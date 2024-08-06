# ZUrl

Simple URL-Shortener written in Zig, using an sqlite database.

The sqlite connection is made using the C-Library, the HTTP Server implementation uses [karlseguin/http.zig](https://github.com/karlseguin/http.zig).

This Application is meant to be used behind an NGINX Proxy, which should handle all the Security, SSL etc. Stuff.

# API

The API consits of only two endpoints:

- `POST /create`
- `GET /{key}`

## `POST /create`

This endpoint expects a request body, in this form:

```json
{
    "url": "{url}"
}
```

It creates a new Entry in the Database for the given key and returns it:
```json
{
    "key": "{key}"
}
```

The Key will always be a 5 Character long alpha-numeric string.

## `GET /{key}`

This endpoint looks up the given key and sends a 302 with the Location set to the url found in the database. If there is no key,
it returns a 404.

# Usage

As this is only the API, there should be some kind of Website to interface with creating the urls.

