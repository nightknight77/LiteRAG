#!/usr/bin/env python3
"""
Integration test script for LiteRAG system
"""
import requests
import json
import time

RAG_API_URL = "http://localhost:8000"
EMBEDDING_API_URL = "http://localhost:8001"

def test_health_checks():
    """Test health endpoints"""
    print("Testing health checks...")
    
    # Test embedding service
    try:
        response = requests.get(f"{EMBEDDING_API_URL}/health")
        print(f"Embedding service: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"Embedding service error: {e}")
    
    # Test RAG API
    try:
        response = requests.get(f"{RAG_API_URL}/health")
        print(f"RAG API: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"RAG API error: {e}")

def test_document_ingestion():
    """Test document ingestion"""
    print("\nTesting document ingestion...")
    
    sample_doc = {
        "text": """
        Python is a high-level programming language. It was created by Guido van Rossum and first released in 1991.
        Python is known for its simple syntax and readability. It supports multiple programming paradigms including
        procedural, object-oriented, and functional programming.
        
        Machine Learning with Python is very popular. Libraries like scikit-learn, TensorFlow, and PyTorch make
        it easy to implement machine learning algorithms. Python's ecosystem includes many data science tools
        like NumPy, Pandas, and Matplotlib.
        """,
        "metadata": {
            "source": "python_intro",
            "topic": "programming"
        }
    }
    
    try:
        response = requests.post(f"{RAG_API_URL}/ingest", json=sample_doc)
        print(f"Ingestion response: {response.status_code}")
        print(f"Response: {response.json()}")
        return True
    except Exception as e:
        print(f"Ingestion error: {e}")
        return False

def test_query():
    """Test querying the RAG system"""
    print("\nTesting queries...")
    
    queries = [
        "What is Python?",
        "Tell me about machine learning libraries",
        "Who created Python?",
        "What programming paradigms does Python support?"
    ]
    
    for query in queries:
        try:
            response = requests.post(f"{RAG_API_URL}/query", json={"query": query, "limit": 3})
            print(f"\nQuery: {query}")
            print(f"Response: {response.status_code}")
            
            if response.status_code == 200:
                results = response.json()["results"]
                for i, result in enumerate(results):
                    print(f"  Result {i+1} (score: {result['score']:.4f}): {result['text'][:100]}...")
            else:
                print(f"Error: {response.text}")
                
        except Exception as e:
            print(f"Query error: {e}")

def main():
    print("LiteRAG Test Script")
    print("=" * 50)
    
    # Wait a bit for services to start
    print("Waiting 5 seconds for services to be ready...")
    time.sleep(5)
    
    test_health_checks()
    
    if test_document_ingestion():
        # Wait a bit for indexing
        time.sleep(2)
        test_query()
    else:
        print("Skipping query test due to ingestion failure")

if __name__ == "__main__":
    main()