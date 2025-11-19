#!/bin/bash

# Local Testing Script for Mirror API
# This script runs the complete test suite locally

set -e

echo "==================================="
echo "Mirror API - Local Testing Script"
echo "==================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv venv
fi

# Activate virtual environment
echo -e "${GREEN}Activating virtual environment...${NC}"
source venv/bin/activate

# Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
pip install -q --upgrade pip
pip install -q -r requirements.txt

# Run linting (optional)
echo -e "${GREEN}Running code quality checks...${NC}"
pip install -q pylint flake8 black
black --check . || echo -e "${YELLOW}Code formatting issues found. Run 'black .' to fix.${NC}"
flake8 --max-line-length=100 --exclude=venv,__pycache__ . || echo -e "${YELLOW}Linting issues found.${NC}"

# Run tests
echo -e "${GREEN}Running unit tests...${NC}"
python -m pytest tests/ -v \
    --cov=. \
    --cov-report=term-missing \
    --cov-report=html \
    --cov-report=xml \
    --junitxml=junit/test-results.xml

# Check test results
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi

# Display coverage report
echo -e "${GREEN}Coverage report generated in htmlcov/index.html${NC}"

# Test the example case specifically
echo -e "${GREEN}Testing the example case: fOoBar25 -> 52RAbOoF${NC}"
python -c "
from main import transform_word
result = transform_word('fOoBar25')
expected = '52RAbOoF'
if result == expected:
    print(f'✓ Example test passed: {result}')
else:
    print(f'✗ Example test failed: Expected {expected}, got {result}')
    exit(1)
"

echo -e "${GREEN}==================================="
echo -e "All tests completed successfully!"
echo -e "===================================${NC}"
