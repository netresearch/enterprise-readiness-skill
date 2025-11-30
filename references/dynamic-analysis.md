# Dynamic Analysis Guide

> OpenSSF Badge Criteria: `dynamic_analysis`, `dynamic_analysis_unsafe`, `dynamic_analysis_enable_assertions`

## Overview

Dynamic analysis examines program behavior during execution, catching issues that static
analysis cannot detect. This guide covers implementation for various languages.

## Go Dynamic Analysis

### Race Detection

The Go race detector finds data races at runtime:

```yaml
# .github/workflows/ci.yml
- name: Race detection
  run: go test -race ./...
```

**Local usage:**
```bash
# Run tests with race detector
go test -race ./...

# Run application with race detector
go run -race main.go

# Build with race detector (for testing only, not production)
go build -race -o app-race .
```

**Common race patterns detected:**
- Unsynchronized map access
- Concurrent slice modification
- Shared variable access without mutex
- Channel misuse

### Fuzz Testing

Go 1.18+ includes native fuzzing:

```go
// fuzz_test.go
func FuzzParseInput(f *testing.F) {
    // Seed corpus
    f.Add("valid input")
    f.Add("")
    f.Add("special!@#$%")

    f.Fuzz(func(t *testing.T, input string) {
        // Function should not panic
        result, err := ParseInput(input)
        if err != nil {
            return // Errors are acceptable
        }
        // Verify invariants
        if result.Length != len(input) {
            t.Errorf("length mismatch")
        }
    })
}
```

**Running fuzz tests:**
```bash
# Run for 60 seconds
go test -fuzz=FuzzParseInput -fuzztime=60s ./...

# Run until failure
go test -fuzz=FuzzParseInput ./...

# Run with specific seed corpus
go test -fuzz=FuzzParseInput -fuzzdir=testdata/fuzz ./...
```

**CI integration:**
```yaml
- name: Fuzz tests
  run: |
    go test -fuzz=. -fuzztime=2m ./...
```

### Memory Sanitizer (CGO)

For CGO code, use memory sanitizers:

```bash
# Address sanitizer (ASan)
CC=clang CGO_ENABLED=1 go test -msan ./...

# Requires clang and libmsan
```

### Integration Testing with Assertions

Enable runtime assertions in tests:

```go
// main.go
var assertionsEnabled = false

func assert(condition bool, msg string) {
    if assertionsEnabled && !condition {
        panic("assertion failed: " + msg)
    }
}

// main_test.go
func TestMain(m *testing.M) {
    assertionsEnabled = true
    os.Exit(m.Run())
}
```

---

## Python Dynamic Analysis

### Fuzz Testing with Atheris

```python
# fuzz_test.py
import atheris
import sys

def TestOneInput(data):
    fdp = atheris.FuzzedDataProvider(data)
    try:
        my_function(fdp.ConsumeString(100))
    except ValueError:
        pass  # Expected errors

atheris.Setup(sys.argv, TestOneInput)
atheris.Fuzz()
```

**CI integration:**
```yaml
- name: Fuzz tests
  run: |
    pip install atheris
    timeout 120 python fuzz_test.py || true
```

### Memory Profiling

```python
# Use memory_profiler
from memory_profiler import profile

@profile
def my_function():
    # Function code
    pass
```

### pytest Assertions

```python
# conftest.py
import pytest

def pytest_configure(config):
    # Enable assertions in optimized mode
    import builtins
    builtins.__debug__ = True
```

---

## Rust Dynamic Analysis

### Miri (Undefined Behavior Detection)

```bash
# Install Miri
rustup +nightly component add miri

# Run tests under Miri
cargo +nightly miri test
```

### Sanitizers

```bash
# Address sanitizer
RUSTFLAGS="-Z sanitizer=address" cargo +nightly test

# Thread sanitizer
RUSTFLAGS="-Z sanitizer=thread" cargo +nightly test

# Memory sanitizer
RUSTFLAGS="-Z sanitizer=memory" cargo +nightly test
```

### cargo-fuzz

```bash
# Install
cargo install cargo-fuzz

# Create fuzz target
cargo fuzz init
cargo fuzz add my_target

# Run
cargo +nightly fuzz run my_target
```

---

## JavaScript/TypeScript Dynamic Analysis

### Jest with Coverage

```javascript
// jest.config.js
module.exports = {
  collectCoverage: true,
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
    },
  },
};
```

### Fuzzing with jsfuzz

```javascript
// fuzz.js
const jsfuzz = require('jsfuzz');

function fuzz(data) {
  const str = data.toString();
  myFunction(str);
}

module.exports = { fuzz };
```

---

## CI/CD Integration

### Comprehensive Dynamic Analysis Workflow

```yaml
# .github/workflows/dynamic-analysis.yml
name: Dynamic Analysis

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  race-detection:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
      - name: Race detector
        run: go test -race -v ./...

  fuzz-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
      - name: Fuzz tests
        run: |
          # Run each fuzz test for 1 minute
          for fuzz in $(go test -list 'Fuzz.*' ./... 2>/dev/null | grep Fuzz); do
            go test -fuzz="$fuzz" -fuzztime=1m ./... || true
          done

  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
      - name: Integration tests
        run: go test -v -tags=integration ./...
        env:
          DATABASE_URL: postgres://postgres:test@localhost/test
```

---

## OSS-Fuzz Integration

For long-term fuzzing, consider [OSS-Fuzz](https://google.github.io/oss-fuzz/):

1. Create `project.yaml`:
```yaml
homepage: "https://github.com/org/repo"
language: go
primary_contact: "maintainer@example.com"
```

2. Create `Dockerfile`:
```dockerfile
FROM gcr.io/oss-fuzz-base/base-builder-go

RUN git clone --depth 1 https://github.com/org/repo /src/repo
WORKDIR /src/repo
COPY build.sh /src/
```

3. Create `build.sh`:
```bash
#!/bin/bash
compile_native_go_fuzzer github.com/org/repo/pkg FuzzFunction fuzz_function
```

---

## Metrics and Reporting

### Coverage with Dynamic Analysis

```yaml
- name: Generate coverage report
  run: |
    go test -race -coverprofile=coverage.out -covermode=atomic ./...
    go tool cover -html=coverage.out -o coverage.html

- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    files: coverage.out
    flags: dynamic-analysis
```

### Tracking Fuzz Coverage

```bash
# Generate fuzz coverage
go test -fuzz=Fuzz -fuzztime=5m -coverprofile=fuzz.out ./...
go tool cover -func=fuzz.out
```

---

## Badge Criteria Verification

### `dynamic_analysis` (Met if any of these are true)
- [ ] Fuzz tests exist and run in CI
- [ ] Race detector runs in CI
- [ ] Memory sanitizers used (if CGO)
- [ ] Integration tests with real dependencies

### `dynamic_analysis_unsafe` (For memory-unsafe languages)
- [ ] Address sanitizer enabled
- [ ] Memory sanitizer enabled
- [ ] Undefined behavior sanitizer enabled

### `dynamic_analysis_enable_assertions` (Met if)
- [ ] Tests run without `-O` optimization flag
- [ ] Debug assertions enabled in test builds
- [ ] Panic on assertion failure in tests

---

## Resources

- [Go Fuzz Testing](https://go.dev/doc/security/fuzz/)
- [Go Race Detector](https://go.dev/doc/articles/race_detector)
- [OSS-Fuzz](https://google.github.io/oss-fuzz/)
- [AFL++ Fuzzer](https://github.com/AFLplusplus/AFLplusplus)
- [Atheris Python Fuzzer](https://github.com/google/atheris)
