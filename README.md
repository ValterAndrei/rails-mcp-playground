# README

- Install dependencies in your VScode
  - [Devcontainer](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

- Start the Rails server:
```bash
bin/rails server -b 0.0.0.0 -p 3000
```

- Start the Rails server with rdbg (for debugging):
```bash
bundle exec rdbg --open --port 12345 --host 0.0.0.0 --nonstop --command -- \
  bin/rails server -b 0.0.0.0 -p 3000
```

- Run tests:
```bash
bin/rails test
```
