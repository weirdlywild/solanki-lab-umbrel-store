# ContextForge refuses to start without these two, so they must exist on every
# start and must never appear in git. derive_entropy is deterministic per device
# seed, so they are stable across restarts and updates without being stored.
#
# The plain `export VAR="$(derive_entropy ...)"` form is used rather than
# `export VAR="${VAR:-$(derive_entropy ...)}"`: the latter is the interpolation
# pattern that silently overwrote merged values in this store before.
export APP_CONTEXTFORGE_JWT_SECRET_KEY="$(derive_entropy "${app_entropy_identifier}-jwt-secret")"
export APP_CONTEXTFORGE_AUTH_ENCRYPTION_SECRET="$(derive_entropy "${app_entropy_identifier}-auth-encryption")"
# The platform admin password is derived too, so it is never in git. A post-start
# hook copies it into the app data directory where the operator can read it,
# because a derived value cannot be guessed by anyone who does not have the seed.
export APP_CONTEXTFORGE_ADMIN_PASSWORD="$(derive_entropy "${app_entropy_identifier}-platform-admin")"
