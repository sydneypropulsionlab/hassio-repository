# Changelog

## [6.0.10-p13] - 2026-10-15

### Added

- SMTP settings (host, port, security, username, password, from address) in
  the add-on configuration.

### Fixed

- Adding members to a project failed because the built-in email settings were
  invalid (TLS and SSL both on, pointing at `localhost`). Without an SMTP host,
  emails are now printed to the add-on log instead.

## [6.0.10-p12] - 2026-10-15

### Changed

- Public sign-up is disabled. New users join by invitation from a project, or
  are created by an admin at `/admin/`.

## [6.0.10-p11] - 2026-10-14

### Fixed

- Django admin CSS/JS and media (attachments, avatars) links were malformed
  (`https:/host/...`), so the admin page loaded unstyled.

## [6.0.10-p10] - 2026-10-14

### Fixed

- Redirects (e.g. `/admin` → `/admin/`, admin login) pointed at
  `http://<host>:8081/...` when Taiga was reached through a reverse proxy.
  Redirects are now relative.

## [6.0.10-p9] - 2026-10-14

### Fixed

- Postgres and RabbitMQ hostnames were hard-coded to the upstream repository's
  `9547a9e0-` prefix, so the add-on couldn't reach them when installed from a
  fork. They are now derived automatically (`host: auto`).
- taiga-events now uses the configured RabbitMQ connection and secret key.

## [6.0.10-p8] - 2026-10-14

### Added

- Direct web access on port 8081 alongside ingress, so Taiga can sit behind a
  reverse proxy (e.g. Nginx Proxy Manager / Cloudflare Tunnel) on its own domain.

## [6.0.10-p5] - 2023-02-12

### Fixed

- Automatic backup of multiple projects

## [6.0.10-p4] - 2023-02-12

### Added

- Automatic backup of all projects to the Home Assistant 'share' folder

## [6.0.10-p3] - 2023-02-12

### Added

- Configurable postgres name, user, host and database.

## [6.0.10-p2] - 2023-02-10

### Fixed

- Panel icon

## [6.0.10-p1] - 2023-02-10

### Added

- Panel icon

## [6.0.10] - 2023-02-08

### Added

- Full taiga installation with events.
- Taiga version 6.0.10
