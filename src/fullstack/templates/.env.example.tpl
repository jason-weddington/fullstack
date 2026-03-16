##if AUTH
# JWT secret — change this in production
JWT_SECRET=dev-secret-change-me
##endif
##if POSTGRES
# PostgreSQL connection URL
DATABASE_URL=postgresql://localhost/{{name}}
##endif
