luau --profile -O2 benchmarks/$1.luau
python3 bin/perfgraph.py profile.out >profile.svg
rm -rf bin/__pycache__
rm profile.out
open profile.svg
