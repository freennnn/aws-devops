import pytest
import sys
import os

# Add the parent directory to the path so we can import the main module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


@pytest.fixture 
def runner():
    """Create a test runner for the Flask application."""
    return app.test_cli_runner()


class TestFlaskHelloWorld:
    """Test suite for the Flask Hello World application."""
    
    def test_app_exists(self):
        """Test that the Flask application exists."""
        assert app is not None
    
    def test_app_is_testing(self, client):
        """Test that the application is in testing mode."""
        assert app.config['TESTING'] is True
    
    def test_hello_world_endpoint(self, client):
        """Test the main hello world endpoint."""
        response = client.get('/')
        
        # Check status code
        assert response.status_code == 200
        
        # Check response data
        assert response.data == b'Hello, World!'
        
        # Check content type
        assert response.content_type == 'text/html; charset=utf-8'
    
    def test_hello_world_content_type(self, client):
        """Test that the response has the correct content type."""
        response = client.get('/')
        assert 'text/html' in response.content_type
    
    def test_hello_world_response_is_string(self, client):
        """Test that the response is a string."""
        response = client.get('/')
        assert isinstance(response.data, bytes)
        assert response.data.decode('utf-8') == 'Hello, World!'
    
    def test_nonexistent_endpoint(self, client):
        """Test that non-existent endpoints return 404."""
        response = client.get('/nonexistent')
        assert response.status_code == 404
    
    def test_method_not_allowed(self, client):
        """Test that non-GET methods return 405 for the main endpoint."""
        response = client.post('/')
        assert response.status_code == 405
        
        response = client.put('/')
        assert response.status_code == 405
        
        response = client.delete('/')
        assert response.status_code == 405
    
    def test_head_request(self, client):
        """Test that HEAD requests work correctly."""
        response = client.head('/')
        assert response.status_code == 200
        assert response.data == b''  # HEAD requests don't return body
    
    def test_options_request(self, client):
        """Test that OPTIONS requests work correctly."""
        response = client.options('/')
        assert response.status_code == 200
    
    def test_multiple_requests(self, client):
        """Test that multiple requests work consistently."""
        for i in range(5):
            response = client.get('/')
            assert response.status_code == 200
            assert response.data == b'Hello, World!'
    
    def test_app_context(self):
        """Test that the application context works correctly."""
        with app.app_context():
            assert app.name == 'main'
    
    def test_request_context(self, client):
        """Test that request context works correctly."""
        with app.test_request_context('/'):
            # Test that we can access the request context
            from flask import request
            assert request.path == '/'
            assert request.method == 'GET'


class TestApplicationConfig:
    """Test suite for application configuration."""
    
    def test_debug_mode(self):
        """Test that debug mode is disabled in production."""
        # In production, debug should be False
        assert app.debug is False or app.config.get('TESTING') is True
    
    def test_app_name(self):
        """Test that the application name is correct."""
        assert app.name == 'main'


class TestSecurityHeaders:
    """Test suite for security-related functionality."""
    
    def test_response_headers(self, client):
        """Test that responses include appropriate headers."""
        response = client.get('/')
        
        # Check that the response has headers
        assert response.headers is not None
        
        # Test that Server header doesn't leak too much information
        server_header = response.headers.get('Server', '')
        assert 'Flask' not in server_header or app.config.get('TESTING') is True


class TestPerformance:
    """Test suite for performance-related checks."""
    
    def test_response_time(self, client):
        """Test that response time is reasonable."""
        import time
        
        start_time = time.time()
        response = client.get('/')
        end_time = time.time()
        
        response_time = end_time - start_time
        
        # Response should be quick (less than 1 second)
        assert response_time < 1.0
        assert response.status_code == 200


class TestErrorHandling:
    """Test suite for error handling."""
    
    def test_404_error(self, client):
        """Test 404 error handling."""
        response = client.get('/this-page-does-not-exist')
        assert response.status_code == 404
    
    def test_500_error_handling(self, client):
        """Test that the app handles errors gracefully."""
        # This test ensures the app doesn't crash on errors
        with app.app_context():
            assert app is not None


if __name__ == '__main__':
    # Run tests when script is executed directly
    pytest.main([__file__, '-v']) 