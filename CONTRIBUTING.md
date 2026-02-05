# Contributing to SwiftAI

Thanks for considering contributing to SwiftAI! Here's how to get started.

## Development Setup

```bash
git clone https://github.com/muhittincamdali/SwiftAI.git
cd SwiftAI
swift build
swift test
```

## What to Contribute

- **New ML algorithms** — Naive Bayes, PCA, DBSCAN, Gradient Boosting, etc.
- **Neural network layers** — Conv1D, Conv2D, LSTM, GRU, Attention
- **Performance** — Accelerate optimizations, Metal compute shaders
- **Tests** — More coverage, edge cases, benchmarks
- **Documentation** — Examples, tutorials, DocC
- **Bug fixes** — Always welcome

## Code Style

- Follow Swift API Design Guidelines
- Use `Accelerate` for vectorized operations where possible
- All public APIs need documentation comments
- Prefer value types, use classes only for mutable state (e.g., layers with parameters)
- Mark types as `Sendable` where appropriate

## Pull Request Process

1. Fork the repo and create a feature branch
2. Write tests for new functionality
3. Make sure `swift test` passes
4. Submit a PR with a clear description

## Commit Messages

Format: `type(scope): description`

- `feat(neural)`: add LSTM layer
- `fix(tensor)`: correct matmul for non-square matrices
- `docs(readme)`: update installation instructions
- `test(kmeans)`: add edge case tests
- `perf(dense)`: optimize forward pass with vDSP

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
