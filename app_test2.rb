#Load required modules
require 'sinatra'
require 'sinatra/reloader'
require 'mysql2'
require 'builder'
require 'rack'
require 'stringio'
require 'socket'

class MyApp < Sinatra::Base
        set :bind, "0.0.0.0"
        set :port, "4567"
        set :raise_errors, false
        set :show_exceptions, false


        get '/' do
                redirect to("/index")
        end

        #When /index page is called, mysql_client method is called
        get "/index" do
                mysql_client
                index_template
        end

        #When user click [Update], update method is called and page is redirected to /index
        get "/runUpdate" do
                update
                redirect "/index"
        end

        #Returns the insert_template
        get "/runInsert" do
                insert_template
        end

        #Values Posted Insert
        post "/runInsert" do
                $location_name = params[:location]
                $limit = params[:limit]
                insert
                "Building: " + $location_name + "Limit:  " + $limit
                back_to_index
        end

        #Delete template is retrieved and displayed
        get "/runDelete" do
                delete_template
        end

        #Values posted to Delete
        post "/runDelete" do
                $store_id = params[:store_id]
                delete
                back_to_index
        end

        #About template is retrieved and displayed
        get "/runAbout" do
                about_template
        end

#       error do
#               redirect to('/')
#       end

        error 404 do
                page_not_found_template
        end


        #Initialize mysql_conn with mysql database connection
        def mysql_conn
                client = Mysql2::Client.new(
                                :host => '192.168.0.64',
				:port => '31967',
                                :username => 'root',
                                :password => 'toor',
                                :database => 'internship',
                                :reconnect => true,
                                :encoding => 'utf8'
                        )
                return client
        end

        #Regex Expression to check if params is integers only!
        def contains_nums(string)
                string.scan(/\D/).empty?
        end

        def ip_valid
                puts "CONTAINER ATTEMPTING TO CONNECT TO DB"
                addr_infos = Socket.ip_address_list

                addr_infos.each do |addr_info|
                        if addr_info.ip_address =~ /192.168.80\.[0-9]{1,3}/
                                valid_IP = addr_info.ip_address
                        end

                        puts "CONTAINER SUCCESSFULLY CONNECTED TO " + valid_IP.to_s
                        return valid_IP.to_s
                end
        end

        #BOOT FUNCTION
        def mysql_client
                puts "LOADING BOOT PROGRAM!"
                table_arr = []

                #Query results from safeEntry
                #results = mysql_conn.query("SELECT * FROM safeEntry ORDER BY crowd_level ASC;")
                results = mysql_conn.query("SELECT * FROM safeEntry ORDER BY store_id ASC;")

                #Store each result entry into dictionary before being stored in table_arr
                results.each do |row|
                        table_arr << {"Location ID" => row["store_id"].to_s, "Location" => row["store_address"], "Crowd Level" => row["crowd_level"].to_s, "Mall Limit" => row["crowd_limit"].to_s}
                end

                #Create HTML table
                $xm = Builder::XmlMarkup.new(:indent => 2)
                $xm.table {
                        $xm.tr { table_arr[0].keys.each { |key| $xm.th(key)}}
                        table_arr.each { |row| $xm.tr {row.values.each { |value| $xm.td(value)}}}
                }

                mysql_conn.close
                puts "BOOT PROGRAM LOADED!"
        end

        #UPDATE FUNCTION
        def update
        puts "LOADING UPDATE SEQUENCE!"

        crowd_limit = []

        #Query safeEntry for no. of entries
        results = mysql_conn.query("SELECT crowd_limit FROM safeEntry;")

        results.each do |row|
                crowd_limit << row["crowd_limit"].to_s
        end

        #generate crowd_level numbers using crowd_limit
        for i in 0..results.count
                if crowd_limit[i].to_i <= 5000
                        rand_num = rand 5000
                elsif crowd_limit[i].to_i <= 10000
                        rand_num = rand 10000
                else
                        rand_num = rand 15000
                end

                #query statement to update crowd_level
                mysql_conn.query("UPDATE safeEntry SET crowd_level=" + rand_num.to_s + " WHERE store_id=" + (i + 1).to_s + ";")
        end

        mysql_conn.close
        puts "UPDATE SEQUENCE LOADED!"
        end

        #INSERT FUNCTION
        def insert
                puts "LOADING INSERT SEQUENCE!"

                #initialization of function variables
                id_num_list = []
                limit = $limit.to_s
                location = $location_name.to_s
                i = 0
                insert_here = 0
                neg_num_list = []

                id_num = mysql_conn.query("SELECT store_id FROM safeEntry;")

                id_num.each do |row|
                        id_num_list << row["store_id"].to_s
                end

                while i <= id_num.count do
                        if (i+1 != id_num_list[i])
                                insert_here = id_num_list[i].to_i - 1
                        end
                        i = i + 1
                end


                if location.empty? != TRUE && limit.empty? != TRUE
                        limit_num_check = contains_nums(limit)
                        if limit_num_check == TRUE
                                if insert_here != 0
                                        mysql_conn.query("INSERT INTO safeEntry (store_id, store_address, crowd_level , crowd_limit) VALUES(" + insert_here.to_s + ", '"  + location + "', 0, " + limit  + ");")
                                        puts "STATEMENT A HAS BEEN QUERIED!"
                                else
                                       mysql_conn.query("INSERT INTO safeEntry (store_id, store_address, crowd_level, crowd_limit) VALUES(" + (id_num.count + 1).to_s + ", '" + location + ", 0, " + limit + ");")
                                        puts "STATEMENT B HAS BEEN QUERIED!"
                                end
                        else
                                puts "LIMIT DOES NOT CONTAIN INTEGERS"
                        end
                end

                neg_num = mysql_conn.query("SELECT store_id FROM safeEntry WHERE store_id=-1")

                neg_num.each do |row|
                        neg_num_list << row["store_id"].to_s
                end

                if neg_num_list.any? == true
                        mysql_conn.query("UPDATE safeEntry SET store_id=" + (id_num.count + 1).to_s  + " WHERE store_id=-1;")
                end

                mysql_conn.close
                puts "INSERT SEQUENCE LOADED!"
        end

        #DELETE FUNCTION
        def delete
                puts "LOADING DELETE SEQUENCE!"

                pre_delete_list = []
                after_delete_list = []
                neg_num_list = []
                store_id = $store_id.to_s

                pre_delete = mysql_conn.query("SELECT store_id FROM safeEntry;")

                pre_delete.each do |row|
                        pre_delete_list << row["store_id"].to_s
                end

                if store_id.empty? != TRUE
                        store_id_num_check = contains_nums(store_id)
                        if store_id_num_check == TRUE
                                puts "STORE ID CONTAINS INTEGERS"
                                mysql_conn.query("DELETE FROM safeEntry WHERE store_id=" + store_id + ";")
                                after_delete = mysql_conn.query("SELECT store_id FROM safeEntry;")

                                after_delete.each do |row|
                                        after_delete_list << row["store_id"].to_s
                                end

                                for i in 0..pre_delete_list.count
                                        if pre_delete_list[i] != after_delete_list[i]
                                                mysql_conn.query("UPDATE safeEntry SET store_id=" + (after_delete_list[i].to_i - 1).to_s + " WHERE store_id=" + pre_delete_list[i].to_s  + ";")
                                        end
                                end

                                neg_num = mysql_conn.query("SELECT store_id FROM safeEntry WHERE store_id=-1")

                                neg_num.each do |row|
                                        neg_num_list << row["store_id"].to_s
                                end

                                if neg_num_list.any? == true
                                        mysql_conn.query("UPDATE safeEntry SET store_id=" + (after_delete_list.count + 1).to_s  + " WHERE store_id=-1;")
                                end
                                mysql_conn.close
                        else
                                puts "STORE ID DOES NOT CONTAIN INTEGERS"
                        end
                end

                puts "DELETE SEQUENCE LOADED!"
        end

        def index_template
                "
                <html>
                        <head>
                                <meta charset='utf-8'>
                                <link rel='stylesheet' type='text/css' href='/application.css'/>
                                <title>Safe Entry Management Portal</title>
                        </head>
                        <body>
                                <header>
                                        <div class='sg_gov'>
                                                <p>A Singapore Government Agency Website</p>
                                        </div>
                                        <div class='safeEntry_directory'>
                                                <nav class='nav_bar'>
                                                        <a class='safeEntry_img' href='/index'>
                                                                <img src='https://www.ndi-api.gov.sg/assets/img/safe-entry/SafeEntry_logo_inline.png' alt='Safe Entry Logo'/>
                                                        </a>
                                                        <ul>
                                                                <li><a href='/runDelete'>Delete</a></li>
                                                                <li><a href='/runInsert'>Insert</a></li>
                                                                <li><a href='/runUpdate'>Refresh</a></li>
                                                                <li><a href='/runAbout'>About</a></li>
                                                        </ul>
                                                </nav>
                                        </div>
                                        <div class='whereami'>
                                                <h1>You are current in: Home Page</h1>
                                        </div>
                                </header>
                                <section>
                                        <p>Welcome to the Safe Entry Management Portal(SEMP)! Here you'll be able to access the crowd levels of various shopping malls and buildings. Simply click on the <b>Refresh</b> to update the page with new records. Click <b>Insert</b> to add a new building to the list! Click <b>Delete</b> to remove a building from the list! Click <b>About</b> to find out more about Safe Entry Check-Ins and Check-Outs! Let's all do our part to stop the spread of the virus!<br></br><b><i> #SGCLEAN</i></b><br><b><i> #SGUNITED!</i></b></br></p>
                                        <br>
                                </section>
                                <section class='center'>
                                        #{$xm}
                                        <br>
                                        #{'Last Updated: ' + Time.now.ctime}
                                        </br></br>
                                </section>
                        </body>
                </html>
                "
        end

        def insert_template
                "
                <html>
                        <head>
                                <meta charset='utf-8'>
                                <link rel='stylesheet' type='text/css' href='/application.css'/>
                                <title>SEMP - Insert Page</title>
                                <script>
                                        function validateForm() {
                                                 var x = document.forms['Form']['location'].value;
                                                 var y = document.forms['Form']['limit'].value;
                                                 if (x == '' || x == null || y == '' || y == null) {
                                                        alert('Please fill up the empty fields');
                                                        return false;
                                                }
                                        }
                                </script>
                        </head>
                        <body>
                                <header>
                                        <div class='sg_gov'>
                                                <p>A Singapore Government Agency Website</p>
                                        </div>
                                        <div class='safeEntry_directory'>
                                                <nav class='nav_bar'>
                                                        <a class='safeEntry_img' href='/index'>
                                                                <img src='https://www.ndi-api.gov.sg/assets/img/safe-entry/SafeEntry_logo_inline.png' alt='Safe Entry Logo'/>
                                                        </a>
                                                        <ul>
                                                                <li><a href='/runDelete'>Delete</a></li>
                                                                <li><a href='/runInsert'>Insert</a></li>
                                                                <li><a href='/runUpdate'>Refresh</a></li>
                                                                <li><a href='/runAbout'>About</a></li>
                                                        </ul>
                                                </nav>
                                        </div>
                                        <div class='whereami'>
                                                <h1>You are current in: Insert Page</h1>
                                        </div>
                                </header>
                                <section>
                                        <p>Please state the name of the store followed by the crowd limit!</p>
                                        <div class='form_box'>
                                                <form method='post' action='/runInsert' name='Form' OnSubmit='return validateForm()'>
                                                        <label for='location'>Store Name:</label>
                                                        <input type='text' name='location'><br></br>
                                                        <label for='location'>Crowd Limits:</label>
                                                        <input type='text' name='limit'><br></br>
                                                        <input type='submit' value='Submit'>
                                                        <a href='/index'>
                                                                <input type='button' value='Back'>
                                                        </a>
                                                </form>
                                        </div>
                                </section>
                        </body>
                </html>
                "
        end

        def delete_template
                "
                <html>
                        <head>
                                <meta charset='utf-8'>
                                <link rel='stylesheet' type='text/css' href='/application.css'/>
                                <title>SEMP - Delete Page</title>
                                <script>
                                        function validateForm() {
                                                 var x = document.forms['Form']['store_id'].value;
                                                 if (x == '' || x == null) {
                                                        alert('Store ID must be filled out');
                                                        return false;
                                                }
                                        }
                                </script>
                        </head>
                        <body>
                                <header>
                                        <div class='sg_gov'>
                                                <p>A Singapore Government Agency Website</p>
                                        </div>
                                        <div class='safeEntry_directory'>
                                                <nav class='nav_bar'>
                                                        <a class='safeEntry_img' href='/index'>
                                                                <img src='https://www.ndi-api.gov.sg/assets/img/safe-entry/SafeEntry_logo_inline.png' alt='Safe Entry Logo'/>
                                                        </a>
                                                        <ul>
                                                                <li><a href='/runDelete'>Delete</a></li>
                                                                <li><a href='/runInsert'>Insert</a></li>
                                                                <li><a href='/runUpdate'>Refresh</a></li>
                                                                <li><a href='/runAbout'>About</a></li>
                                                        </ul>
                                                </nav>
                                        </div>
                                        <div class='whereami'>
                                                <h1>You are current in: Delete Page</h1>
                                        </div>
                                </header>
                                <section>
                                        <p>Refer to the table below and key in the respective Store ID in the input box!</p>
                                </section>
                                <section class='center'>
                                        #{$xm}
                                        <br>
                                </section>
                                <section class='form_box'>
                                                <form method='post' name='Form' onSubmit='return validateForm()' action='/runDelete'>
                                                        <label for='store_id'>Store ID:</label>
                                                        <input type='text' name='store_id'><br></br></br>
                                                        <input type='submit' value='Submit'>
                                                        <a href='/index'>
                                                                <input type='button' value='Back'>
                                                        </a>
                                                </form>
                                        </div>
                                </section>
                        </body>
                </html>
                "
        end

        def about_template
                "
                <html>
                         <head>
                                <meta charset='utf-8'>
                                <link rel='stylesheet' type='text/css' href='/application.css'/>
                                <title>SEMP - Insert Page</title>
                                <style>
                                        h1, h3 {text-align: center;}
                                        p {text-align: center;}
                                </style>

                        </head>
                        <body>
                                <header>
                                        <div class='sg_gov'>
                                                <p>A Singapore Government Agency Website</p>
                                        </div>
                                        <div class='safeEntry_directory'>
                                                <nav class='nav_bar'>
                                                        <a class='safeEntry_img' href='/index'>
                                                                <img src='https://www.ndi-api.gov.sg/assets/img/safe-entry/SafeEntry_logo_inline.png' alt='Safe Entry Logo'/>
                                                        </a>
                                                        <ul>
                                                                <li><a href='/runDelete'>Delete</a></li>
                                                                <li><a href='/runInsert'>Insert</a></li>
                                                                <li><a href='/runUpdate'>Refresh</a></li>
                                                                <li><a href='/runAbout'>About</a></li>
                                                        </ul>
                                                </nav>
                                        </div>
                                        <div class='whereami'>
                                                <h1>You are current in: About Page</h1>
                                        </div>
                                </header>
                                <section>
                                        <br>
                                        <h2>What is Safe Entry?</h2>
                                        <p>SafeEntry is a national digital check-in system that logs the NRIC/FINs and mobile numbers of individuals visiting hotspots, workplaces of essential services, as well as selected public venues to prevent and control the transmission of COVID-19 through activities such as contact tracing and identification of COVID-19 clusters. Individuals can choose to check in/out from SafeEntry at entry/exit points using any of the following methods:</p><p>(a) Scan QR code: Use the SingPass Mobile app, TraceTogether app, your mobile phone's camera function or a recommended QR scanner app to scan a QR code and submit your personal particulars; or</p><p>(b) Scan ID card: Present an identification card barcode (e.g. NRIC, Passion card, Pioneer Generation card, Merdeka Generation card, driver's licence, Transitlink concession card, student pass, work permit, SingPass Mobile app, TraceTogether app) to be scanned by staff; or</p><p>(c) Select from a list of nearby locations: Use the SingPass Mobile app's - SafeEntry Check-In function to select a location and check in.</p>
                                        </br>
                                        <h2>Why is Safe Entry being deployed to more places?</h2>
                                        <p>As more activities and services gradually resume following the circuit breaker period, it is important that efforts to prevent and control the transmission of COVID-19 such as contact tracing and identification of COVID-19 clusters can be done quickly to limit the risk of further community transmission. SafeEntry helps support and quicken these efforts to prevent and control the incidence or transmission of COVID-19 as it provides authorities with a record of individuals who enter and exit places. The records will reduce the time needed to identify potential close contacts of COVID-19 patients and potential COVID-19 clusters. This is important so that we can continue advancing towards fewer restrictions on our movements, and our daily lives</p>
                                        <br>
                                        <h2>Why do we need to use SafeEntry instead of existing vendor management systems?</h2>
                                        <p>The use of SafeEntry is mandatory because a common system used by all establishments would allow data to be made available to MOH quickly, so as to facilitate efforts to prevent and control the transmission of COVID-19 through activities such as contact tracing and identification of COVID-19 clusters. SafeEntry allows information of visitors and employees who may have come into contact with COVID-19 cases to be sent to the authorities automatically. Contact data collected by SafeEntry is only used by authorised personnel, and stringent measures are in place to safeguard the data in accordance with the Government's data security standards.</p>
                                        </br>
                                        <h2>Can I use an alternative visitor management system instead of SafeEntry?</h2>
                                        <p>From 12 May onwards, businesses are required to use SafeEntry to collect entry information of employees and visitors on their premises. Businesses that need to retain the use of their current system for the collection of data that are not required in the SafeEntry system (e.g. purpose of visit, employee's ID number) are required to implement SafeEntry on top of their existing system. To cater to visitors who are not able to scan QR codes or do not have their identification cards with them, businesses are advised to also assist individuals to check in through the manual entry function in SafeEntry using their NRIC, or the webform in SafeEntry with the QR code using any available device.</p>
                                        <br>
                                        <h2>What happens if safeEntry breaks down? Is there flexibility in the enforcement of SafeEntry?</h2>
                                        <p>Businesses should tap on the alternate mode of SafeEntry in the unlikely event that their preferred mode breaks down, i.e. use SafeEntry QR as back-up if SafeEntry NRIC is the preferred mode, and vice versa. Businesses may do so by setting up the alternate mode at <a href='https://www.SafeEntry.gov.sg'/>SafeEntry.gov.sg</a>. SafeEntry does not recommend hard copy form filling as a back-up.

The common use of SafeEntry by all establishments would allow data to be automatically sent to MOH. Hard copy recording of particulars would present a gap in this automated process and affect the contact tracing process.</p>
                                        </br>
                                </section>
                        </body>
                </html>
                "
        end


        def back_to_index
                "
                <html>
                         <head>
                                <meta charset='utf-8'>
                                <link rel='stylesheet' type='text/css' href='/application.css'/>
                                <title>SEMP - Insert Page</title>
                        </head>
                        <body>
                                <header>
                                        <div class='sg_gov'>
                                                <p>A Singapore Government Agency Website</p>
                                        </div>
                                        <div class='safeEntry_directory'>
                                                <nav class='nav_bar'>
                                                        <a class='safeEntry_img' href='/index'>
                                                                <img src='https://www.ndi-api.gov.sg/assets/img/safe-entry/SafeEntry_logo_inline.png' alt='Safe Entry Logo'/>
                                                        </a>
                                                        <ul>
                                                                <li><a href='/runDelete'>Delete</a></li>
                                                                <li><a href='/runInsert'>Insert</a></li>
                                                                <li><a href='/runUpdate'>Refresh</a></li>
                                                                <li><a href='/runAbout'>About</a></li>
                                                        </ul>
                                                </nav>
                                        </div>
                                </header>
                                <section>
                                        <div class='form_box'>
                                                <p>Click the [Back] button to return to the index page.</p><br></br>
                                                <a href='/index'>
                                                        <input type='submit' value='Back'/>
                                                </a>
                                        </div>
                                </section>
                        </body>
                </html>
                "
        end

        def construction_template
                "
                <html>
                         <head>
                                <meta charset='utf-8'>
                                <link rel='stylesheet' type='text/css' href='/application.css'/>
                                <title>SEMP - Insert Page</title>
                        </head>
                        <body>
                                <header>
                                        <div class='sg_gov'>
                                                <p>A Singapore Government Agency Website</p>
                                        </div>
                                        <div class='safeEntry_directory'>
                                                <nav class='nav_bar'>
                                                        <a class='safeEntry_img' href='/index'>
                                                                <img src='https://www.ndi-api.gov.sg/assets/img/safe-entry/SafeEntry_logo_inline.png' alt='Safe Entry Logo'/>
                                                        </a>
                                                        <ul>
                                                                <li><a href='/runDelete'>Delete</a></li>
                                                                <li><a href='/runInsert'>Insert</a></li>
                                                                <li><a href='/runUpdate'>Refresh</a></li>
                                                                <li><a href='/runAbout'>About</a></li>
                                                        </ul>
                                                </nav>
                                        </div>
                                </header>
                                <section>
                                        <h1>I'm sorry, this page is currently under routine maintenance.</h1>
                                        <h3>We apologise for any inconveniences caused!</h3>
                                </section>
                        </body>
                </html>
                "

        end

        def page_not_found_template
                "
                <html>
                         <head>
                                <meta charset='utf-8'>
                                <link rel='stylesheet' type='text/css' href='/application.css'/>
                                <title>SEMP - Insert Page</title>
                        </head>
                        <body>
                                <header>
                                        <div class='sg_gov'>
                                                <p>A Singapore Government Agency Website</p>
                                        </div>
                                        <div class='safeEntry_directory'>
                                                <nav class='nav_bar'>
                                                        <a class='safeEntry_img' href='/index'>
                                                                <img src='https://www.ndi-api.gov.sg/assets/img/safe-entry/SafeEntry_logo_inline.png' alt='Safe Entry Logo'/>
                                                        </a>
                                                        <ul>
                                                                <li><a href='/runDelete'>Delete</a></li>
                                                                <li><a href='/runInsert'>Insert</a></li>
                                                                <li><a href='/runUpdate'>Refresh</a></li>
                                                                <li><a href='/runAbout'>About</a></li>
                                                        </ul>
                                                </nav>
                                        </div>
                                </header>
                                <section>
                                        <h1>404 - PAGE NOT FOUND!</h1>
                                        <br>
                                        <p>I'm sorry. It seems that the page you are looking for is not available.</p>
                                        <br>
                                </section>
                        </body>
                </html>
                "
        end
end
