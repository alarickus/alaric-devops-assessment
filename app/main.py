"""
Mirror API - Flask Application
Provides health check and word transformation endpoints
"""

from flask import Flask, request, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Database configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/mirrordb')

def get_db_connection():
    """Create and return a database connection"""
    try:
        conn = psycopg2.connect(DATABASE_URL)
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        raise

def init_db():
    """Initialize database table if not exists"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Create table for storing mirror transformations
        cur.execute("""
            CREATE TABLE IF NOT EXISTS mirror_words (
                id SERIAL PRIMARY KEY,
                original_word VARCHAR(255) NOT NULL,
                transformed_word VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        # Create index for better query performance
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_mirror_words_original 
            ON mirror_words(original_word);
        """)
        
        conn.commit()
        cur.close()
        conn.close()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization error: {e}")
        # Don't fail app startup if DB is not available yet
        pass

def transform_word(word):
    """
    Transform a word according to the rules:
    1. Swap case of letters (upper -> lower, lower -> upper)
    2. Keep non-letter characters as is
    3. Reverse the entire string
    
    Example: 'fOoBar25' -> 'FOObAR25' -> '52RAbOoF'
    """
    # Step 1 & 2: Swap case
    swapped = word.swapcase()
    
    # Step 3: Reverse the string
    reversed_word = swapped[::-1]
    
    return reversed_word

def save_to_database(original, transformed):
    """Save the original and transformed word pair to database"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute(
            "INSERT INTO mirror_words (original_word, transformed_word) VALUES (%s, %s)",
            (original, transformed)
        )
        
        conn.commit()
        cur.close()
        conn.close()
        logger.info(f"Saved to database: {original} -> {transformed}")
        return True
    except Exception as e:
        logger.error(f"Database save error: {e}")
        return False

@app.route('/api/health', methods=['GET'])
def health_check():
    """
    Health check endpoint
    Returns: JSON with status ok
    """
    return jsonify({"status": "ok"}), 200

@app.route('/api/mirror', methods=['GET'])
def mirror_word():
    """
    Mirror endpoint - transforms the input word
    Query parameter: word
    Returns: JSON with transformed word
    """
    # Get the word from query parameter
    word = request.args.get('word', '')
    
    # Validate input
    if not word:
        return jsonify({
            "error": "Missing 'word' query parameter"
        }), 400
    
    # Transform the word
    transformed = transform_word(word)
    
    # Save to database
    save_to_database(word, transformed)
    
    # Return response
    return jsonify({
        "transformed": transformed
    }), 200

@app.route('/api/history', methods=['GET'])
def get_history():
    """
    Optional endpoint to retrieve transformation history
    Returns: JSON array of all transformations
    """
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT original_word, transformed_word, created_at 
            FROM mirror_words 
            ORDER BY created_at DESC 
            LIMIT 100
        """)
        
        records = cur.fetchall()
        cur.close()
        conn.close()
        
        # Convert datetime to string for JSON serialization
        for record in records:
            if record['created_at']:
                record['created_at'] = record['created_at'].isoformat()
        
        return jsonify(records), 200
    except Exception as e:
        logger.error(f"Error fetching history: {e}")
        return jsonify({"error": "Database error"}), 500

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    # Initialize database on startup
    init_db()
    
    # Run the application
    port = int(os.getenv('PORT', 4004))
    app.run(host='0.0.0.0', port=port, debug=False)
