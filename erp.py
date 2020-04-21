# Import the Python driver for PostgreSQL
import psycopg2
import datetime
from tabulate import tabulate

# Create a connection credentials to the PostgreSQL database
try:

    fksel = {"job": ["j.name"], "customer": ["c.first_name", "c.last_name"], "model": [
        "m.model_number"], "employee": ["e.first_name", "e.last_name"]}

    logins = {"ADMIN": ["admin_1", "jw8s0F41"], "SALES": [
        "sales_1", "jw8s0F42"], "ENGINEERING": ["engg_1", "jw8s0F43"], "HR": ["hr_1", "jw8s0F44"]}

    # setup the data base
    print("Do you want to setup DB (Create DB named ERP in the postgres)?(True/False)")
    if(input() == "True"):
        conn = psycopg2.connect(
            user="postgres",
            password="postgres",
            host="localhost",
            port="5432",
            database="ERP"
        )
        cur = conn.cursor()
        sql_file = open('bkp_latest.sql', 'r')
        cur.execute(sql_file.read())
        conn.commit()
        cur.close()
        conn.close()

    connection = psycopg2.connect(
        user="postgres",
        password="postgres",
        host="localhost",
        port="5432",
        database="ERP"
    )

    # Create a cursor connection object to a PostgreSQL instance and print the connection properties.
    cursor = connection.cursor()
    print(connection.get_dsn_parameters(), "\n")

    # Display the PostgreSQL version installed
    cursor.execute("SELECT version();")
    record = cursor.fetchone()
    print(record)

    def get_fk(tabName):
        cursor.execute(
            "SELECT kcu.column_name, ccu.table_name AS foreign_table_name FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = %s;",
            (tabName,))
        return {el[0]: el[1] for el in cursor.fetchall()}

    def get_col(tabName):
        cursor.execute("SELECT column_name,data_type FROM information_schema.columns WHERE table_schema = %s AND table_name   = %s AND column_name <> %s and column_name <> %s;",
                        ("public", tabName, "id", "order_date"))
        return cursor.fetchall()

    def get_tables():
        cursor.execute(
            "select table_name from information_schema.tables where table_schema = 'public' and table_type = 'BASE TABLE';")
        return cursor.fetchall()

    def get_views():
        cursor.execute(
            "select table_name from information_schema.tables where table_schema = 'public' and table_type = 'VIEW';")
        return cursor.fetchall()

    def delete_table_data(tabName, id):
        qry = "delete from "+tabName+" where id = %s"
        params = []
        params.append(id)
        cursor.execute(qry, params)
        connection.commit()

    def insert_table_data(tabName):
        cols = get_col(tabName)
        colList = [el[0] for el in cols]
        fk = get_fk(tabName)
        i = 0
        params = []
        placeholders = []
        for col in cols:
            print("enter", col[0])
            if col[0] in fk:
                select_view_table_data(fk[col[0]], [])
                print("Enter id of your choice:")
            ip = input()
            if not ip:
                placeholders.append("NULL")
            else:
                if col[1] == "boolean":
                    placeholders.append(ip)
                else:
                    params.append(ip)
                    placeholders.append("%s")
            i = i+1
        qry = "insert into "+tabName + \
            " ( "+" , ".join(colList)+") Values (" + \
            " , ".join(placeholders) + " ) RETURNING id;"
        cursor.execute(qry, params)
        connection.commit()
        return cursor.fetchone()[0]

    def update_table_data(tabName, id):
        cols = get_col(tabName)
        colList = [el[0] for el in cols]
        fk = get_fk(tabName)
        qry = "select " + " , ".join(colList) + \
            " from "+tabName + " where id = %s"
        params = []
        params.append(id)
        data = select_record(qry, params, True)
        i = 0
        params = []
        for col in colList:
            print("enter", col, "(", data[i], ")")
            if col in fk:
                select_view_table_data(fk[col], [])
                print("Enter id of your choice:")
            ip = input()
            if not ip:
                params.append(data[i])
            else:
                params.append(ip)
            i = i+1
        params.append(id)
        qry = "update "+tabName+" set " + \
            " =%s, ".join(colList)+"=%s where id = %s;"
        cursor.execute(qry, params)
        connection.commit()
        print("Record updated successfull in " + tabName + ", id:", id)

    def select_record(qry, params, one):
        cursor.execute(qry, params)
        if one:
            record = cursor.fetchone()
        else:
            record = cursor.fetchall()
        return record

    def select_view_table_data(tabName, cols):
        fk = get_fk(tabName)
        fkTables = ""
        fkFields = []
        for i in fk:
            fkTables += "join "+fk[i]+" "+fk[i][0:1] + \
                " ON "+tabName[0]+"."+i+" = "+fk[i][0]+".id "
            fkFields += fksel[fk[i]]
        if(len(cols) == 0):
            cursor.execute(
                "SELECT column_name,data_type FROM information_schema.columns WHERE table_schema = %s AND table_name   = %s;", ("public", tabName))
            cols = cursor.fetchall()
            headers = [tabName[0]+"."+el[0] for el in cols]
        else:
            headers = cols
        headers += fkFields
        qry = "select " + " ,".join(headers)+" from " + \
            tabName+" "+tabName[0]+" "+fkTables+";"
        print("\nCurrent data without filters in the", tabName,
                "table")
        print(tabulate(select_record(qry, [], False),
                        headers=headers, tablefmt="github", numalign="left"))

    def curd_point(oper, tabName):
                if(oper == 'a'):
                    print("Record is inserted into the table" +
                            tabName + ", ID:", insert_table_data(tabName))
                elif(oper == 'b'):
                    print("Enter Id for updating")
                    update_table_data(tabName, input())
                elif(oper == 'c'):
                    print("Enter Id for deleting")
                    delete_table_data(tabName, input())
                elif(oper == 'd'):
                    select_view_table_data(tabName, [])

    # fetch the employee id
    print("Please enter your employee id :")
    cursor.execute(
        "SELECT e.id,e.job_type,e.first_name,e.last_name,j.name from employee e join job j on e.job_type =j.id  where e.id = %s;", (input()))
    record = cursor.fetchone()
    
    # setting the login details
    userid = record[0]
    role = record[1]
    
    # welcome message
    print("Welcome", record[2], record[3],
            "you have logged in as", record[4])
    
    # TODO: uncomment below adding login data to the table
    # cursor.execute(
    #     "insert into login (user_id, role_id) values (%s,%s) RETURNING id;", (userid, role))
    # connection.commit()
    # loginId = cursor.fetchone()[0]
    # print("login is successfull id : ", loginId)
    
    # display menu by role
    logout = True
    while logout:
        # admin access
        if(role == 1):
            print("what would you like to do today?\na.Create a new employee\nb.Create a new customer\nc.CRUD on tables\nd.Grant access\ne.Access report\nf.logout\nenter your choice:")
            selected = input()
            if(selected == 'a'):
                print("emp inserted successfull id : ",
                        insert_table_data("employee"))
            elif(selected == 'b'):
                print("customer inserted successfull id : ",
                        insert_table_data("customer"))
            elif(selected == 'c'):
                tables = [el[0] for el in get_tables()]
                for i in tables:
                    print(tables.index(i), i)
                print("select table to setup")
                tId = int(input())
                print(
                    "select Operation\na.insert\nb.update\nc.delete\nd.select")
                curd_point(input(), tables[tId])
            elif(selected == 'd'):
                print("Enter employee id to set change role")
                updateid = input()
                curd_point("d", "job")
                print("Enter new role id")
                cursor.execute(
                    "update employee set job_type = %s where id = %s;", (input(), updateid))
                connection.commit()
                print("Role updated successfully")
            elif(selected == 'e'):
                views = [el[0] for el in get_views()]
                for i in views:
                    print(views.index(i), i)
                print("select view to execute")
                tId = int(input())
                curd_point("d", views[tId])
            else:
                logout = False
        # sales access
        elif (role == 2):
            print("what would you like to do today?\na.view customer\nb.update customer\nc.create an Order\nd.Access sales reports\ne.logout\nenter your choice:")
            choice = input()
            if(choice == 'a'):
                curd_point("d", "customer")
            elif(choice == 'b'):
                curd_point("b", "customer")
            elif(choice == 'c'):
                curd_point("a", "orders")
            elif(choice == 'd'):
                curd_point("d", "sales_emp_cust")
            else:
                logout = False
        # Engineer access
        elif (role == 3):
            print("what would you like to do today?\na.Access model\nb.Update model\nc.Access inventory\nd.Update inventory\ne.Access employee\nf.logout\nenter your choice:")
            choice = input()
            if(choice == 'a'):
                curd_point("d", "model")
            elif(choice == 'b'):
                curd_point("b", "model")
            elif(choice == 'c'):
                curd_point("d", "inventory")
            elif(choice == 'd'):
                curd_point("b", "inventory")
            elif(choice == 'e'):
                select_view_table_data(
                    "employee", ["id", "first_name", "last_name", "is_active", "email", "job_type"])
            else:
                logout = False
        # HR access
        elif (role == 4):
            print(
                "what would you like to do today?\na.Access employee\nb.Update employee\nc.Sales report\nd.logout\nenter your choice:")
            choice = input()
            if (choice == 'a'):
                select_view_table_data("employee", [])
            elif (choice == 'b'):
                print("Enter employee id:")
                update_table_data("employee", input())
            elif (choice == 'c'):
                select_view_table_data("sales_emp_cust", [])
            else:
                logout = False

# Handle the error throws by the command that is useful when using Python while working with PostgreSQL
except(Exception, psycopg2.Error) as error:
    print("Error connecting to PostgreSQL database", error)
    # cursor.execute("update login set logout_time = %s where id = %s;",
    #                (datetime.datetime.now(), loginId))
    # connection.commit()
    connection = None

# Close the database connection
finally:
    if connection != None:
        # TODO: uncomment logout logic
        # cursor.execute("update login set logout_time = %s where id = %s;",
        #                (datetime.datetime.now(), loginId))
        # connection.commit()
        print("logout is successfull, See you soon")
        cursor.close()
        connection.close()
        print("PostgreSQL connection is now closed")
