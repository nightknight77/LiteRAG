# Vector Databases for Backend Engineers

A practical guide for SQL/NoSQL developers transitioning to vector databases.

## Overview

Vector databases represent a paradigm shift from traditional database concepts. While SQL and NoSQL databases organize data around tables/documents, vector databases organize data around **semantic similarity** in high-dimensional space.

## Schema Comparison

### Traditional Database Schemas

```sql
-- SQL: Fixed schema with columns/types
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    content TEXT,
    created_at TIMESTAMP
);
```

```javascript
// NoSQL (MongoDB): Flexible schema with documents
{
  "_id": ObjectId("..."),
  "title": "Document Title",
  "content": "Document content...",
  "tags": ["tag1", "tag2"],
  "metadata": {
    "author": "John Doe",
    "category": "technical"
  }
}
```

### Vector Database Schema (Qdrant)

Vector databases use a **hybrid approach** - fixed vector structure with flexible metadata:

```json
{
  "id": "uuid-string",
  "vector": [0.1, -0.3, 0.8, ...],  // FIXED: exactly 768 dimensions
  "payload": {                       // FLEXIBLE: any JSON structure
    "text": "your document content",
    "filename": "example.py",
    "language": "python",
    "custom_field": "anything",
    "nested": {
      "data": "works too"
    }
  }
}
```

## Key Architectural Differences

| Aspect | SQL | NoSQL | Vector DB |
|--------|-----|-------|-----------|
| **Primary Access** | Primary keys, indexes | Document IDs | Vector similarity |
| **Query Method** | WHERE clauses | Find/Match queries | Semantic similarity search |
| **Schema** | Rigid structure | Flexible documents | Hybrid (fixed vectors + flexible metadata) |
| **Indexing** | B-tree, Hash | Various (compound, text) | HNSW (Hierarchical Navigable Small World) |
| **Relationships** | Foreign keys, JOINs | References, $lookup | Implicit via similarity |
| **Scaling** | Vertical/horizontal | Horizontal sharding | Vector-space partitioning |

## LiteRAG Implementation Example

### Document Ingestion Process

```python
# 1. Text chunking
chunks = chunk_text(document.text)

# 2. Vector generation (FIXED: must be exactly 768 dimensions)
embeddings = model.encode(chunks)  # Returns 768-dimensional vectors

# 3. Storage with flexible metadata
for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
    point = {
        "id": str(uuid.uuid4()),
        "vector": embedding.tolist(),  # [0.123, -0.456, ...] (768 floats)
        "payload": {
            "text": chunk,
            "chunk_index": i,
            **document.metadata  # Any custom fields you add
        }
    }
    qdrant_client.upsert(collection_name="documents", points=[point])
```

### Query Process

```python
# Traditional SQL approach
SELECT * FROM documents 
WHERE content LIKE '%machine learning%' 
ORDER BY created_at DESC;

# Vector database approach
query_vector = model.encode(["machine learning"])
results = qdrant_client.search(
    collection_name="documents",
    query_vector=query_vector[0],
    limit=10
)
# Returns semantically similar content, even without exact keyword matches
```

## Practical Examples

### Flexible Metadata Schemas

You can store any metadata structure without schema migrations:

```json
// Code files
{
  "text": "async def fetch_data()...",
  "type": "code",
  "language": "python",
  "project": "literag",
  "complexity": "beginner",
  "tags": ["async", "http", "api"],
  "functions": ["fetch_data", "parse_response"]
}

// Documentation
{
  "text": "Vector databases store high-dimensional...",
  "type": "documentation",
  "section": "architecture",
  "audience": "backend-engineers",
  "related_topics": ["embeddings", "similarity-search"]
}

// Meeting notes
{
  "text": "Discussed Q4 roadmap priorities...",
  "type": "meeting",
  "date": "2024-01-15",
  "attendees": ["Alice", "Bob"],
  "action_items": 3,
  "project": "literag"
}
```

## Vector Dimensions and Model Constraints

### Dimension Consistency

Unlike traditional databases where you can add columns dynamically, vector dimensions are **immutable** for a collection:

```python
# Collection created with 768 dimensions (all-mpnet-base-v2)
collection_config = {
    "vectors": {
        "size": 768,        # CANNOT be changed later
        "distance": "Cosine"
    }
}

# All vectors MUST be exactly 768 dimensions
valid_vector = [0.1, 0.2, ...] # 768 floats ✓
invalid_vector = [0.1, 0.2]    # 2 floats ✗ - will fail
```

### Model Migration Impact

Changing embedding models requires database migration:

```bash
# Old model: all-MiniLM-L6-v2 (384 dimensions)
# New model: all-mpnet-base-v2 (768 dimensions)

# Migration steps:
1. Stop services
2. Clear vector database
3. Update model configuration
4. Re-ingest all documents
```

## Performance Characteristics

### Traditional Database Performance

```sql
-- SQL: O(log n) with proper indexing
SELECT * FROM documents WHERE title = 'specific title';

-- SQL: O(n) without indexing
SELECT * FROM documents WHERE content LIKE '%keyword%';
```

### Vector Database Performance

```python
# Vector similarity: O(log n) with HNSW index
# But searches ENTIRE semantic space, not just exact matches
results = qdrant_client.search(
    collection_name="documents",
    query_vector=embedding,
    limit=10
)
```

## Best Practices for Backend Engineers

### 1. Think Semantically, Not Structurally

```python
# Traditional mindset: exact matches
WHERE category = 'python' AND difficulty = 'beginner'

# Vector mindset: semantic similarity
query = "simple Python examples for beginners"
# Will find relevant content even without exact category/difficulty fields
```

### 2. Use Metadata for Filtering

```python
# Combine semantic search with traditional filtering
results = qdrant_client.search(
    collection_name="documents",
    query_vector=embedding,
    query_filter={
        "must": [
            {"key": "language", "match": {"value": "python"}},
            {"key": "difficulty", "match": {"value": "beginner"}}
        ]
    },
    limit=10
)
```

### 3. Design Metadata for Your Use Cases

```python
# Good: Structured, queryable metadata
{
  "text": "function implementation...",
  "type": "code",
  "language": "python",
  "project": "literag",
  "tags": ["async", "api"],
  "created_at": "2024-01-15T10:30:00Z"
}

# Avoid: Unstructured, hard-to-query metadata
{
  "text": "function implementation...",
  "misc_info": "python async api literag 2024-01-15"
}
```

## Migration Strategies

### From SQL to Vector DB

```python
# SQL table structure
documents(id, title, content, category, tags, created_at)

# Vector equivalent
{
  "vector": embedding_of_title_and_content,
  "payload": {
    "text": title + " " + content,  # Combined for embedding
    "title": title,             # Preserved for display
    "category": category,       # For filtering
    "tags": tags,              # For filtering
    "created_at": created_at   # For sorting
  }
}
```

### Hybrid Approaches

You don't have to choose one or the other:

```python
# Keep SQL for structured queries
SELECT user_id, document_count FROM users WHERE created_at > '2024-01-01';

# Use vector DB for semantic search
vector_results = qdrant_client.search(query="machine learning concepts")

# Combine results in application layer
combined_results = enrich_with_user_data(vector_results, sql_connection)
```

## Conclusion

Vector databases complement rather than replace traditional databases. They excel at:

- **Semantic search**: Finding similar content without exact keyword matches
- **Flexible metadata**: Schema-free additional data storage
- **AI/ML integration**: Direct compatibility with embedding models

For backend engineers, think of vector databases as a specialized tool for semantic search and similarity-based retrieval, while maintaining traditional databases for structured queries, transactions, and relational data.

## Further Reading

- [VECTOR_DB_EXPLAINED.md](./VECTOR_DB_EXPLAINED.md) - Technical deep-dive into vector operations
- [Qdrant Documentation](https://qdrant.tech/documentation/) - Official Qdrant docs
- [Sentence Transformers](https://www.sbert.net/) - Embedding model documentation