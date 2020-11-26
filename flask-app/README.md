# A simple flask app

To run it with gunicorn:

```
gunicorn app:app
```

Requires `HEALTH_TOKEN=foo` to be healthy.

For arguments check help:

```
gunicorn --help
```

or https://docs.gunicorn.org/en/stable/settings.html
