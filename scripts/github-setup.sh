#!/bin/bash

# GitHub Repository Setup Commands
# Run these AFTER creating repository on GitHub

echo "🔗 Setting up GitHub repository connection..."

# Replace YOUR_USERNAME with your actual GitHub username
GITHUB_USERNAME="YOUR_USERNAME"
REPO_NAME="ai-media-comics-website"

echo "📝 Repository will be at: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"

echo "⚡ Commands to run after creating GitHub repository:"
echo ""
echo "git remote add origin https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
echo "git push -u origin main"
echo ""
echo "🎯 After pushing, your repository will be available at:"
echo "https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
