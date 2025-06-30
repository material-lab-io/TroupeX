# Contributing to TroupeX

Thank you for your interest in contributing to TroupeX! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Respect differing opinions and experiences

## Getting Started

1. **Fork the Repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/TroupeX.git
   cd TroupeX
   ```

2. **Set Up Development Environment**
   ```bash
   # Run the setup script
   ./setup-dev-deps.sh
   
   # Setup the database
   cd mastodon
   RAILS_ENV=development bin/setup
   ```

3. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

## Development Process

### 1. Before You Start

- Check existing issues and pull requests to avoid duplicate work
- For major changes, open an issue first to discuss the approach
- Ensure your development environment is up to date

### 2. Making Changes

Follow these guidelines when making changes:

#### Frontend (JavaScript/React)

- Use functional components with hooks
- Follow existing component patterns
- Keep components focused and reusable
- Use TypeScript for new components

```javascript
// Good: Functional component with proper typing
const MyComponent: React.FC<Props> = ({ title, onClick }) => {
  return (
    <div className='my-component' onClick={onClick}>
      <h2>{title}</h2>
    </div>
  );
};
```

#### Backend (Ruby/Rails)

- Follow Rails conventions
- Keep controllers thin, logic in services
- Use strong parameters
- Write meaningful model validations

```ruby
# Good: Service object pattern
class CreatePostService
  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    post = @user.posts.build(@params)
    
    if post.save
      notify_followers(post)
      ServiceResult.success(post)
    else
      ServiceResult.failure(post.errors)
    end
  end
  
  private
  
  def notify_followers(post)
    # notification logic
  end
end
```

### 3. Writing Tests

All code changes must include appropriate tests:

#### Frontend Tests

```bash
# Run all frontend tests
cd mastodon && yarn test

# Run specific test file
yarn test:js path/to/component.test.js

# Run with coverage
yarn test --coverage
```

#### Backend Tests

```bash
# Run all backend tests
cd mastodon && bundle exec rspec

# Run specific test
bundle exec rspec spec/models/user_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### 4. Code Quality

Before submitting:

```bash
# Frontend
cd mastodon
yarn lint              # Check linting
yarn format           # Format code
yarn typecheck        # Check TypeScript

# Backend
bundle exec rubocop   # Check Ruby style
bundle exec rubocop -A # Auto-fix issues

# Run all checks
yarn test && bundle exec rspec && yarn lint && bundle exec rubocop
```

## Coding Standards

### JavaScript/TypeScript

- Use ESLint configuration provided
- Prefer `const` over `let`
- Use template literals for string interpolation
- Async/await over promises chains
- Meaningful variable names

### Ruby

- Follow Ruby Style Guide
- Use RuboCop configuration provided
- Prefer symbols for hash keys
- Use guard clauses
- Keep methods under 10 lines when possible

### CSS/SCSS

- Use BEM naming convention
- Keep specificity low
- Use variables for colors and spacing
- Mobile-first responsive design

### Git Commits

- Use clear, descriptive commit messages
- Follow conventional commits format:
  ```
  type(scope): subject
  
  body
  
  footer
  ```
- Types: feat, fix, docs, style, refactor, test, chore

Examples:
```
feat(messaging): add direct message notifications
fix(auth): resolve login redirect issue
docs(readme): update installation instructions
```

## Pull Request Process

1. **Ensure Your Code is Ready**
   - All tests pass
   - Code follows style guidelines
   - Documentation is updated
   - Commits are clean and meaningful

2. **Create Pull Request**
   - Use a clear, descriptive title
   - Reference any related issues
   - Provide a detailed description
   - Include screenshots for UI changes

3. **Pull Request Template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   - [ ] Tests pass locally
   - [ ] Added new tests
   - [ ] Tested on mobile
   
   ## Screenshots (if applicable)
   
   ## Related Issues
   Fixes #123
   ```

4. **Code Review**
   - Respond to feedback promptly
   - Make requested changes
   - Keep discussions focused and professional

## Reporting Issues

### Bug Reports

Include:
- Clear, descriptive title
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details (OS, browser, Ruby/Node versions)
- Screenshots or error logs

### Feature Requests

Include:
- Use case description
- Proposed solution
- Alternative solutions considered
- Mockups or examples (if applicable)

## Development Tips

### Hot Reload Development
```bash
# For UI/theme development
./troupe-hot-reload.sh

# For full development with Docker sync
./troupe-dev.sh
```

### Database Management
```bash
# Create migration
cd mastodon
bundle exec rails generate migration AddFieldToModel

# Run migrations
bundle exec rails db:migrate

# Rollback
bundle exec rails db:rollback
```

### Debugging
```bash
# Rails console
cd mastodon && bundle exec rails console

# View logs
tail -f mastodon/log/development.log

# Debug with binding.pry
# Add to code: binding.pry
```

## Getting Help

- Check the [documentation](docs/)
- Search existing issues
- Ask in discussions
- Contact maintainers

## Recognition

Contributors will be recognized in:
- [CONTRIBUTORS.md](CONTRIBUTORS.md)
- Release notes
- Project documentation

Thank you for contributing to TroupeX!