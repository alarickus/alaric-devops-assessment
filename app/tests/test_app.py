"""
Unit tests for Mirror API
Tests health endpoint, mirror transformation, and database integration
"""

import pytest
import sys
import os
from unittest.mock import patch, MagicMock

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from main import app, transform_word, save_to_database

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

class TestHealthEndpoint:
    """Tests for /api/health endpoint"""
    
    def test_health_endpoint_returns_ok(self, client):
        """Test that health endpoint returns status ok"""
        response = client.get('/api/health')
        assert response.status_code == 200
        assert response.json == {"status": "ok"}
    
    def test_health_endpoint_method_get_only(self, client):
        """Test that health endpoint only accepts GET requests"""
        response = client.post('/api/health')
        assert response.status_code == 405

class TestMirrorTransformation:
    """Tests for word transformation logic"""
    
    def test_transform_lowercase(self):
        """Test transformation of lowercase word"""
        result = transform_word('foo')
        assert result == 'OOF'
    
    def test_transform_uppercase(self):
        """Test transformation of uppercase word"""
        result = transform_word('BAR')
        assert result == 'rab'
    
    def test_transform_mixed_case(self):
        """Test transformation of mixed case word"""
        result = transform_word('FoO')
        assert result == 'oOf'
    
    def test_transform_with_numbers(self):
        """Test transformation with numbers"""
        result = transform_word('abc123')
        assert result == '321CBA'
    
    def test_transform_example_case(self):
        """Test the exact example from requirements: fOoBar25 -> 52RAbOoF"""
        result = transform_word('fOoBar25')
        assert result == '52RAbOoF', f"Expected '52RAbOoF' but got '{result}'"
    
    def test_transform_special_characters(self):
        """Test transformation with special characters"""
        result = transform_word('Hello-World!')
        assert result == '!DLROw-OLLEh'
    
    def test_transform_empty_string(self):
        """Test transformation of empty string"""
        result = transform_word('')
        assert result == ''
    
    def test_transform_single_char(self):
        """Test transformation of single character"""
        assert transform_word('a') == 'A'
        assert transform_word('Z') == 'z'
    
    def test_transform_palindrome(self):
        """Test transformation maintains certain patterns"""
        result = transform_word('AaA')
        assert result == 'aAa'

class TestMirrorEndpoint:
    """Tests for /api/mirror endpoint"""
    
    @patch('main.save_to_database')
    def test_mirror_endpoint_basic(self, mock_save, client):
        """Test basic mirror endpoint functionality"""
        mock_save.return_value = True
        
        response = client.get('/api/mirror?word=test')
        assert response.status_code == 200
        assert 'transformed' in response.json
        assert response.json['transformed'] == 'TSET'
    
    @patch('main.save_to_database')
    def test_mirror_endpoint_example_case(self, mock_save, client):
        """Test the exact example: fOoBar25 should return 52RAbOoF"""
        mock_save.return_value = True
        
        response = client.get('/api/mirror?word=fOoBar25')
        assert response.status_code == 200
        assert response.json['transformed'] == '52RAbOoF'
    
    def test_mirror_endpoint_missing_parameter(self, client):
        """Test mirror endpoint with missing word parameter"""
        response = client.get('/api/mirror')
        assert response.status_code == 400
        assert 'error' in response.json
    
    @patch('main.save_to_database')
    def test_mirror_endpoint_empty_word(self, mock_save, client):
        """Test mirror endpoint with empty word"""
        mock_save.return_value = True
        
        response = client.get('/api/mirror?word=')
        assert response.status_code == 400
    
    @patch('main.save_to_database')
    def test_mirror_endpoint_special_chars(self, mock_save, client):
        """Test mirror endpoint with special characters"""
        mock_save.return_value = True
        
        response = client.get('/api/mirror?word=Hello@World!')
        assert response.status_code == 200
        assert 'transformed' in response.json
    
    @patch('main.save_to_database')
    def test_mirror_endpoint_calls_database(self, mock_save, client):
        """Test that mirror endpoint saves to database"""
        mock_save.return_value = True
        
        response = client.get('/api/mirror?word=test')
        assert response.status_code == 200
        mock_save.assert_called_once()
        
        # Check arguments passed to save_to_database
        call_args = mock_save.call_args[0]
        assert call_args[0] == 'test'
        assert call_args[1] == 'TSET'

class TestDatabaseIntegration:
    """Tests for database functionality"""
    
    @patch('main.get_db_connection')
    def test_save_to_database_success(self, mock_get_conn):
        """Test successful database save"""
        # Mock database connection and cursor
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_conn.cursor.return_value = mock_cursor
        mock_get_conn.return_value = mock_conn
        
        result = save_to_database('test', 'TSET')
        
        assert result == True
        mock_cursor.execute.assert_called_once()
        mock_conn.commit.assert_called_once()
    
    @patch('main.get_db_connection')
    def test_save_to_database_failure(self, mock_get_conn):
        """Test database save failure handling"""
        mock_get_conn.side_effect = Exception("Database error")
        
        result = save_to_database('test', 'TSET')
        assert result == False

class TestErrorHandling:
    """Tests for error handling"""
    
    def test_404_handler(self, client):
        """Test 404 error handler"""
        response = client.get('/api/nonexistent')
        assert response.status_code == 404
        assert 'error' in response.json
    
    @patch('main.get_db_connection')
    def test_history_endpoint_database_error(self, mock_get_conn, client):
        """Test history endpoint handles database errors gracefully"""
        mock_get_conn.side_effect = Exception("Database error")
        
        response = client.get('/api/history')
        assert response.status_code == 500
        assert 'error' in response.json

class TestComprehensiveCases:
    """Comprehensive test cases"""
    
    @pytest.mark.parametrize("input_word,expected_output", [
        ('foo', 'OOF'),
        ('bar', 'RAB'),
        ('fOoBar25', '52RAbOoF'),
        ('ABC', 'cba'),
        ('a1B2c3', '3C2b1A'),
        ('Hello World', 'DLROw OLLEh'),
        ('123', '321'),
        ('!@#', '#@!'),
    ])
    def test_transformation_cases(self, input_word, expected_output):
        """Test multiple transformation cases"""
        result = transform_word(input_word)
        assert result == expected_output, f"Input: {input_word}, Expected: {expected_output}, Got: {result}"

if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov=main', '--cov-report=term-missing'])
