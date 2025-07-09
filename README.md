# fluent-plugin-hide-sensitive

A Fluentd filter plugin that hides or removes sensitive fields (e.g., `token`, `password`) from a specified nested key in log records. The plugin moves these fields into a new key (`hidden_keys`) and deletes them from their original location.

## 📦 Installation

```bash
td-agent-gem install fluent-plugin-hide-sensitive
```
## Configuration

```
<filter your.match.tag>
  @type hide_sensitive
  sensitive_keys token, pass
  search_path log.data.message
  output_key hidden_keys
</filter>
```

## example 
### Input
```
{
  "log": {
    "data": {
      "message": {
        "token": "secret123",
        "user": "alice"
      }
    }
  }
}
```
### Output
```
{
    "log": {
      "data": {
        "message": {
          "user": "alice"
        }
      }
    },
    "hidden_keys": {
      "token": "secret123"
    }
}
```