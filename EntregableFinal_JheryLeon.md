# Entregable Final - Tecnología de Base de Datos I

## Migración de tablas, vistas y consultas de verificación  
### MariaDB → PostgreSQL 18

**Estudiante:** Jhery León  
**Asignatura:** Tecnología de Base de Datos I  
**Unidad:** Bloque 3 - Migración de un sistema informático a otro SGBD  
**Docente:** Jared Lopez  
**Fecha:** 24 de septiembre de 2026  

---

# 1. Introducción

El presente informe documenta la migración de la base de datos `employees` desde MariaDB hacia PostgreSQL 18. El proceso incluyó la migración de los datos de las tablas, la migración y adaptación de las vistas, la verificación de los conteos de registros, la validación de la integridad referencial, la comparación mediante checksums SHA-256 y la generación de un backup final de PostgreSQL.

## 1.1 Entorno utilizado

- MariaDB ejecutándose en el contenedor Docker `mariadb`.
- PostgreSQL 18 ejecutándose en el contenedor Docker `postgresql`.
- Base de datos origen: `employees`.
- Base de datos destino: `pdb_employees`.
- Usuario PostgreSQL: `jhery`.
- Herramientas utilizadas: Docker, MariaDB CLI, PostgreSQL `psql`, `\copy`, `pg_dump`, `pg_restore` y `sha256sum`.

---

# 2. Punto 1 - Migración de Tablas

## 2.1 Tablas migradas

La base de datos contiene las siguientes seis tablas:

- `departments`
- `employees`
- `dept_emp`
- `dept_manager`
- `salaries`
- `titles`

Antes de cargar los datos se comprobó que las tablas ya existían en PostgreSQL:

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees -c "\dt"
```

Salida:

```text
           Listado de tablas
 Esquema |    Nombre    | Tipo  | Dueño
---------+--------------+-------+-------
 public  | departments  | tabla | jhery
 public  | dept_emp     | tabla | jhery
 public  | dept_manager | tabla | jhery
 public  | employees    | tabla | jhery
 public  | salaries     | tabla | jhery
 public  | titles       | tabla | jhery
(6 filas)
```

## 2.2 Intento inicial con pgloader

Inicialmente se intentó migrar los datos con `pgloader`. La herramienta logró conectarse a ambos SGBD:

```text
LOG Migrating from #<MYSQL-CONNECTION mysql://root@127.0.0.1:3306/employees>
LOG Migrating into #<PGSQL-CONNECTION pgsql://jhery@127.0.0.1:5432/pdb_employees>
```

Sin embargo, durante la carga se produjo el siguiente error:

```text
ERROR A thread failed with error: Database error: Connection to database server lost.
KABOOM!
DATABASE-CONNECTION-LOST: Database error: Connection to database server lost.
```

Los registros de PostgreSQL mostraron que un proceso interno terminó de forma anormal y el servidor realizó una recuperación automática. Debido a ello, se optó por una migración controlada mediante archivos TSV y `\copy`.

## 2.3 Exportación de datos desde MariaDB

Se creó la carpeta para los archivos intermedios:

```bash
mkdir -p ~/EntregableFinal/datos
cd ~/EntregableFinal
```

### Tabla departments

```bash
docker exec mariadb mariadb --skip-ssl -u root -p"<CONTRASEÑA_MARIADB>" \
-D employees --batch --raw --skip-column-names \
-e "SELECT dept_no, dept_name FROM departments;" \
> datos/departments.tsv
```

### Tabla employees

```bash
docker exec mariadb mariadb --skip-ssl -u root -p"<CONTRASEÑA_MARIADB>" \
-D employees --batch --raw --skip-column-names \
-e "SELECT emp_no, birth_date, first_name, last_name, gender, hire_date FROM employees;" \
> datos/employees.tsv
```

### Tabla dept_emp

```bash
docker exec mariadb mariadb --skip-ssl -u root -p"<CONTRASEÑA_MARIADB>" \
-D employees --batch --raw --skip-column-names \
-e "SELECT emp_no, dept_no, from_date, to_date FROM dept_emp;" \
> datos/dept_emp.tsv
```

### Tabla dept_manager

```bash
docker exec mariadb mariadb --skip-ssl -u root -p"<CONTRASEÑA_MARIADB>" \
-D employees --batch --raw --skip-column-names \
-e "SELECT emp_no, dept_no, from_date, to_date FROM dept_manager;" \
> datos/dept_manager.tsv
```

### Tabla salaries

```bash
docker exec mariadb mariadb --skip-ssl -u root -p"<CONTRASEÑA_MARIADB>" \
-D employees --batch --raw --skip-column-names \
-e "SELECT emp_no, salary, from_date, to_date FROM salaries;" \
> datos/salaries.tsv
```

### Tabla titles

```bash
docker exec mariadb mariadb --skip-ssl -u root -p"<CONTRASEÑA_MARIADB>" \
-D employees --batch --raw --skip-column-names \
-e "SELECT emp_no, title, from_date, to_date FROM titles;" \
> datos/titles.tsv
```

## 2.4 Verificación de archivos exportados

```bash
wc -l datos/*.tsv
```

Salida:

```text
        9 datos/departments.tsv
   331603 datos/dept_emp.tsv
       24 datos/dept_manager.tsv
   300024 datos/employees.tsv
  2844047 datos/salaries.tsv
   443308 datos/titles.tsv
  3919015 total
```

Se exportaron en total **3.919.015 registros**.

## 2.5 Importación de datos en PostgreSQL

La importación se realizó respetando el orden de las relaciones para evitar problemas con claves foráneas.

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees \
-c "\copy departments(dept_no,dept_name) FROM 'datos/departments.tsv' WITH (FORMAT text, DELIMITER E'\t')"
```

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees \
-c "\copy employees(emp_no,birth_date,first_name,last_name,gender,hire_date) FROM 'datos/employees.tsv' WITH (FORMAT text, DELIMITER E'\t')"
```

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees \
-c "\copy dept_emp(emp_no,dept_no,from_date,to_date) FROM 'datos/dept_emp.tsv' WITH (FORMAT text, DELIMITER E'\t')"
```

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees \
-c "\copy dept_manager(emp_no,dept_no,from_date,to_date) FROM 'datos/dept_manager.tsv' WITH (FORMAT text, DELIMITER E'\t')"
```

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees \
-c "\copy salaries(emp_no,salary,from_date,to_date) FROM 'datos/salaries.tsv' WITH (FORMAT text, DELIMITER E'\t')"
```

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees \
-c "\copy titles(emp_no,title,from_date,to_date) FROM 'datos/titles.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL 'NULL')"
```

## 2.6 Conteo final en PostgreSQL

```sql
SELECT 'departments' AS tabla, COUNT(*) FROM departments
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'dept_emp', COUNT(*) FROM dept_emp
UNION ALL
SELECT 'dept_manager', COUNT(*) FROM dept_manager
UNION ALL
SELECT 'salaries', COUNT(*) FROM salaries
UNION ALL
SELECT 'titles', COUNT(*) FROM titles;
```

Salida:

```text
    tabla     |  count
--------------+---------
 departments  |       9
 employees    |  300024
 dept_emp     |  331603
 dept_manager |      24
 salaries     | 2844047
 titles       |  443308
(6 filas)
```

## 2.7 Comparación de conteos

| Tabla | MariaDB | PostgreSQL | Resultado |
|---|---:|---:|---|
| departments | 9 | 9 | Coincide |
| employees | 300024 | 300024 | Coincide |
| dept_emp | 331603 | 331603 | Coincide |
| dept_manager | 24 | 24 | Coincide |
| salaries | 2844047 | 2844047 | Coincide |
| titles | 443308 | 443308 | Coincide |
| **Total** | **3919015** | **3919015** | **Coincide** |

La cantidad de registros en PostgreSQL coincide exactamente con la cantidad exportada desde MariaDB.

---

# 3. Punto 2 - Migración de Vistas

La base de datos origen contiene dos vistas:

- `dept_emp_latest_date`
- `current_dept_emp`

## 3.1 Extracción de vistas desde MariaDB

Se utilizaron los siguientes comandos:

```bash
docker exec mariadb mariadb --skip-ssl -u root -p"<CONTRASEÑA_MARIADB>" employees \
-e "SHOW CREATE VIEW dept_emp_latest_date\G"
```

```bash
docker exec mariadb mariadb --skip-ssl -u root -p"<CONTRASEÑA_MARIADB>" employees \
-e "SHOW CREATE VIEW current_dept_emp\G"
```

La definición lógica de `dept_emp_latest_date` en MariaDB es:

```sql
SELECT
    dept_emp.emp_no,
    MAX(dept_emp.from_date) AS from_date,
    MAX(dept_emp.to_date) AS to_date
FROM dept_emp
GROUP BY dept_emp.emp_no;
```

La definición lógica de `current_dept_emp` en MariaDB es:

```sql
SELECT
    l.emp_no,
    d.dept_no,
    l.from_date,
    l.to_date
FROM dept_emp d
JOIN dept_emp_latest_date l
    ON d.emp_no = l.emp_no
   AND d.from_date = l.from_date
   AND d.to_date = l.to_date;
```

## 3.2 Definiciones adaptadas en PostgreSQL

```sql
CREATE VIEW dept_emp_latest_date AS
SELECT
    emp_no,
    MAX(from_date) AS from_date,
    MAX(to_date) AS to_date
FROM dept_emp
GROUP BY emp_no;
```

```sql
CREATE VIEW current_dept_emp AS
SELECT
    l.emp_no,
    d.dept_no,
    l.from_date,
    l.to_date
FROM dept_emp AS d
JOIN dept_emp_latest_date AS l
    ON d.emp_no = l.emp_no
   AND d.from_date = l.from_date
   AND d.to_date = l.to_date;
```

## 3.3 Verificación de vistas existentes

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees -c "\dv"
```

Salida:

```text
               Listado de vistas
 Esquema |        Nombre        | Tipo  | Dueño
---------+----------------------+-------+-------
 public  | current_dept_emp     | vista | jhery
 public  | dept_emp_latest_date | vista | jhery
(2 filas)
```

## 3.4 Definiciones verificadas en PostgreSQL

Para `dept_emp_latest_date`:

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees \
-c "SELECT pg_get_viewdef('public.dept_emp_latest_date'::regclass, true);"
```

Salida:

```text
SELECT emp_no,
       max(from_date) AS from_date,
       max(to_date) AS to_date
FROM dept_emp
GROUP BY emp_no;
```

Para `current_dept_emp`:

```bash
psql -h 127.0.0.1 -p 5432 -U jhery -d pdb_employees \
-c "SELECT pg_get_viewdef('public.current_dept_emp'::regclass, true);"
```

Salida:

```text
SELECT l.emp_no,
       d.dept_no,
       l.from_date,
       l.to_date
FROM dept_emp d
JOIN dept_emp_latest_date l
  ON d.emp_no = l.emp_no
 AND d.from_date = l.from_date
 AND d.to_date = l.to_date;
```

## 3.5 Pruebas de funcionamiento

```sql
SELECT COUNT(*) FROM dept_emp_latest_date;
```

Resultado:

```text
 count
--------
 300024
(1 fila)
```

```sql
SELECT COUNT(*) FROM current_dept_emp;
```

Resultado:

```text
 count
--------
 300024
(1 fila)
```

Prueba de datos:

```sql
SELECT * FROM current_dept_emp LIMIT 10;
```

Salida:

```text
 emp_no | dept_no | from_date  |  to_date
--------+---------+------------+------------
  10004 | d004    | 1986-12-01 | 9999-01-01
  10018 | d004    | 1992-07-29 | 9999-01-01
  10020 | d004    | 1997-12-30 | 9999-01-01
  10025 | d005    | 1987-08-17 | 1997-10-15
  10027 | d005    | 1995-04-02 | 9999-01-01
  10033 | d006    | 1987-03-18 | 1993-03-24
  10037 | d005    | 1990-12-05 | 9999-01-01
  10038 | d009    | 1989-09-20 | 9999-01-01
  10043 | d005    | 1990-10-20 | 9999-01-01
  10046 | d008    | 1992-06-20 | 9999-01-01
(10 filas)
```

Las dos vistas fueron migradas y funcionan correctamente en PostgreSQL.

---

# 4. Punto 3 - Consultas de Verificación

## 4.1 Integridad referencial

Se verificó la existencia de registros huérfanos en las seis relaciones principales.

Durante esta verificación PostgreSQL mostró inicialmente:

```text
ERROR: could not resize shared memory segment ... No space left on device
```

Para reducir el uso de memoria compartida se deshabilitó temporalmente el paralelismo de la sesión:

```sql
SET max_parallel_workers_per_gather = 0;
SET enable_parallel_hash = off;
```

Luego se ejecutaron las verificaciones de integridad.

Resultado en PostgreSQL:

| Relación | Huérfanos |
|---|---:|
| dept_emp → employees | 0 |
| dept_emp → departments | 0 |
| dept_manager → employees | 0 |
| dept_manager → departments | 0 |
| salaries → employees | 0 |
| titles → employees | 0 |

La misma comprobación se realizó en MariaDB:

```text
relacion                         huerfanos
dept_emp -> employees            0
dept_emp -> departments          0
dept_manager -> employees        0
dept_manager -> departments      0
salaries -> employees            0
titles -> employees              0
```

Por lo tanto, ambos SGBD presentan **0 registros huérfanos** en todas las relaciones comprobadas.

## 4.2 Verificación mediante SHA-256

Para realizar una comparación de contenido se generó un checksum SHA-256 por tabla. Los registros fueron ordenados por sus claves principales antes de calcular el hash, de modo que MariaDB y PostgreSQL produjeran una secuencia equivalente.

| Tabla | SHA-256 MariaDB | SHA-256 PostgreSQL | Resultado |
|---|---|---|---|
| departments | `9e9777ddbe761baddf5d42d0a0fa37ae78ca2db3e9dee6bbfeacc9ebe6fab38c` | `9e9777ddbe761baddf5d42d0a0fa37ae78ca2db3e9dee6bbfeacc9ebe6fab38c` | Coinciden |
| employees | `c7d05d894e4e1413483b6c96521de3e480e24cb692e0f27f142d4df75a4c368d` | `c7d05d894e4e1413483b6c96521de3e480e24cb692e0f27f142d4df75a4c368d` | Coinciden |
| dept_emp | `4e8d7e8d58ae7187bd7939aedfb2b3f9caefc844acc119d5a9f70e5e6c3ddedc` | `4e8d7e8d58ae7187bd7939aedfb2b3f9caefc844acc119d5a9f70e5e6c3ddedc` | Coinciden |
| dept_manager | `d325828f15303b31ba9e9f6ef7c33150401fd6246471acf4170fa1ac08eabd91` | `d325828f15303b31ba9e9f6ef7c33150401fd6246471acf4170fa1ac08eabd91` | Coinciden |
| salaries | `2b1c1a3fc7c4aedaece0831b16bd3e797fd23264309a1f6bc615c05dda3f078c` | `2b1c1a3fc7c4aedaece0831b16bd3e797fd23264309a1f6bc615c05dda3f078c` | Coinciden |
| titles | `d57e0eac15326b15c676e7a9340abf82b2ea50098acb460d15826ac11c067922` | `d57e0eac15326b15c676e7a9340abf82b2ea50098acb460d15826ac11c067922` | Coinciden |

Los seis checksums coinciden exactamente.

## 4.3 Análisis de resultados

La migración fue verificada utilizando tres mecanismos:

1. Comparación de conteos de filas.
2. Verificación de integridad referencial mediante búsqueda de registros huérfanos.
3. Comparación del contenido mediante hashes SHA-256.

Los resultados obtenidos fueron consistentes en los tres casos. Las seis tablas presentan la misma cantidad de registros en ambos SGBD, no se detectaron registros huérfanos y los hashes SHA-256 coinciden para todas las tablas.

Por tanto, no se detectaron diferencias entre los datos exportados desde MariaDB y los datos almacenados finalmente en PostgreSQL.

---

# 5. Backup de PostgreSQL

Se generó un backup en formato personalizado de PostgreSQL:

```bash
pg_dump -h 127.0.0.1 -p 5432 -U jhery \
-Fc -d pdb_employees \
-f pdb_employees.dump
```

Tamaño obtenido:

```text
-rw-r--r-- 1 jhery jhery 34M sep 24 21:45 pdb_employees.dump
```

El `pg_restore` instalado en el sistema anfitrión no soportaba la versión 1.16 del archivo, por lo que la verificación se realizó con la versión de PostgreSQL 18 disponible dentro del contenedor:

```bash
docker exec -i postgresql pg_restore -l < pdb_employees.dump | head -n 30
```

Salida relevante:

```text
Archive created at 2026-09-24 21:45:41 -04
dbname: pdb_employees
TOC Entries: 34
Compression: gzip
Dump Version: 1.16-0
Format: CUSTOM
Dumped from database version: 18.6
Dumped by pg_dump version: 18.6

TYPE public gender_enum
TABLE public dept_emp
VIEW public dept_emp_latest_date
VIEW public current_dept_emp
TABLE public departments
TABLE public dept_manager
TABLE public employees
TABLE public salaries
TABLE public titles
TABLE DATA public departments
TABLE DATA public dept_emp
TABLE DATA public dept_manager
TABLE DATA public employees
TABLE DATA public salaries
TABLE DATA public titles
```

La salida confirma que el backup contiene las tablas, sus datos, las vistas y el tipo enumerado utilizado por la base de datos.

---

# 6. Conclusiones

La migración de la base de datos `employees` desde MariaDB hacia PostgreSQL 18 se completó satisfactoriamente.

Se migraron **3.919.015 registros distribuidos en seis tablas**, además de las dos vistas existentes en la base de datos origen.

La verificación permitió confirmar que:

- Los conteos de registros coinciden entre MariaDB y PostgreSQL.
- No existen registros huérfanos en las relaciones verificadas.
- Los checksums SHA-256 de las seis tablas coinciden exactamente.
- Las vistas `dept_emp_latest_date` y `current_dept_emp` funcionan correctamente en PostgreSQL.
- Se generó y verificó un backup completo de la base de datos destino.

Durante el proceso se presentaron dificultades con la migración automatizada mediante pgloader y con el uso de memoria compartida en PostgreSQL. Estas dificultades fueron solucionadas utilizando una migración controlada mediante archivos TSV y `\copy`, además de ajustar temporalmente el paralelismo para las consultas de verificación.

---

# 7. Archivos del entregable

```text
EntregableFinal/
├── EntregableFinal_JheryLeon.md
├── README.md
├── pdb_employees.dump
└── verificar_checksums.sh
```

Los archivos TSV utilizados durante la migración pueden mantenerse de forma local como evidencia del proceso, pero no son necesarios para restaurar el backup final.

---

# 8. Referencias

- Documentación oficial de PostgreSQL: `psql`, `COPY`, `pg_dump` y `pg_restore`.
- Documentación oficial de MariaDB: cliente `mariadb` y consultas SQL.
- Documentación de Docker.
- Documentación de pgloader.
- Documentación de GitHub.
