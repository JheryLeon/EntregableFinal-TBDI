# Entregable Final - Tecnología de Base de Datos I

Proyecto de migración de la base de datos `employees` desde MariaDB hacia PostgreSQL 18.

## Contenido

- `EntregableFinal_JheryLeon.md`: informe completo de la migración.
- `pdb_employees.dump`: backup de la base de datos PostgreSQL.
- `verificar_checksums.sh`: script utilizado para comparar los datos mediante SHA-256.

## Resumen

- 6 tablas migradas.
- 2 vistas migradas.
- 3.919.015 registros.
- Conteos verificados.
- Integridad referencial validada.
- Checksums SHA-256 coincidentes.
- Backup final de PostgreSQL validado.

## Resultado

Los conteos y checksums coinciden entre MariaDB y PostgreSQL, y no se detectaron registros huérfanos en las relaciones verificadas.
