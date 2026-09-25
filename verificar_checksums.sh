#!/bin/bash

read -s -p "Contraseña PostgreSQL de jhery: " PGPASSWORD
export PGPASSWORD
echo
read -s -p "Contraseña MariaDB root: " MYSQL_PASSWORD
echo
check() {
    tabla="$1"
    mysql_sql="$2"
    pg_sql="$3"

    mysql_hash=$(docker exec mariadb mariadb --skip-ssl \
        -u root -p"$MYSQL_PASSWORD" employees \
        --batch --raw --skip-column-names \
        -e "$mysql_sql" | sha256sum | awk '{print $1}')

    pg_hash=$(psql -h 127.0.0.1 -p 5432 \
        -U jhery -d pdb_employees -At \
        -c "$pg_sql" | sha256sum | awk '{print $1}')

    echo
    echo "Tabla: $tabla"
    echo "MariaDB:    $mysql_hash"
    echo "PostgreSQL: $pg_hash"

    if [ "$mysql_hash" = "$pg_hash" ]; then
        echo "RESULTADO: COINCIDEN"
    else
        echo "RESULTADO: DIFERENTES"
    fi
}

check "departments" \
"SELECT CONCAT(dept_no,'|',dept_name)
 FROM departments
 ORDER BY dept_no;" \
"SELECT dept_no || '|' || dept_name
 FROM departments
 ORDER BY dept_no;"

check "employees" \
"SELECT CONCAT(emp_no,'|',
 DATE_FORMAT(birth_date,'%Y-%m-%d'),'|',
 first_name,'|',last_name,'|',gender,'|',
 DATE_FORMAT(hire_date,'%Y-%m-%d'))
 FROM employees
 ORDER BY emp_no;" \
"SELECT emp_no::text || '|' ||
 birth_date::text || '|' ||
 first_name || '|' || last_name || '|' ||
 gender::text || '|' || hire_date::text
 FROM employees
 ORDER BY emp_no;"

check "dept_emp" \
"SELECT CONCAT(emp_no,'|',dept_no,'|',
 DATE_FORMAT(from_date,'%Y-%m-%d'),'|',
 DATE_FORMAT(to_date,'%Y-%m-%d'))
 FROM dept_emp
 ORDER BY emp_no, dept_no;" \
"SELECT emp_no::text || '|' || dept_no || '|' ||
 from_date::text || '|' || to_date::text
 FROM dept_emp
 ORDER BY emp_no, dept_no;"

check "dept_manager" \
"SELECT CONCAT(emp_no,'|',dept_no,'|',
 DATE_FORMAT(from_date,'%Y-%m-%d'),'|',
 DATE_FORMAT(to_date,'%Y-%m-%d'))
 FROM dept_manager
 ORDER BY emp_no, dept_no;" \
"SELECT emp_no::text || '|' || dept_no || '|' ||
 from_date::text || '|' || to_date::text
 FROM dept_manager
 ORDER BY emp_no, dept_no;"

check "salaries" \
"SELECT CONCAT(emp_no,'|',salary,'|',
 DATE_FORMAT(from_date,'%Y-%m-%d'),'|',
 DATE_FORMAT(to_date,'%Y-%m-%d'))
 FROM salaries
 ORDER BY emp_no, from_date;" \
"SELECT emp_no::text || '|' || salary::text || '|' ||
 from_date::text || '|' || to_date::text
 FROM salaries
 ORDER BY emp_no, from_date;"

check "titles" \
"SELECT CONCAT(emp_no,'|',title,'|',
 DATE_FORMAT(from_date,'%Y-%m-%d'),'|',
 COALESCE(DATE_FORMAT(to_date,'%Y-%m-%d'),'NULL'))
 FROM titles
 ORDER BY emp_no, title, from_date;" \
"SELECT emp_no::text || '|' || title || '|' ||
 from_date::text || '|' ||
 COALESCE(to_date::text,'NULL')
 FROM titles
 ORDER BY emp_no, title, from_date;"

unset PGPASSWORD
