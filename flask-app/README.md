# A simple flask app

Simple but slow, doing things in an inefficient manner and sometimes even hangs completely.

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
