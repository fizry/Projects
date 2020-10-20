#Load required modules
require 'sinatra'
require 'sinatra/reloader'
require 'mysql2'
require 'builder'

#Global variable set to database connection

def mysql_conn
	client = Mysql2::Client.new(
        	        :host => '127.0.0.1',
                	:username => 'root',
	                :password => 'toor',
        	        :database => 'internship',
			:reconnect => true,
                	:encoding => 'utf8'
	        )
	return client
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

post "/runDelete" do
	$store_id = params[:store_id]
	delete
	back_to_index
end


#About template is retrieved and displayed
get "/runAbout" do
        about_template
end

def mysql_client
	puts "LOADING BOOT PROGRAM!"
	table_arr = []

	#Query results from safeEntry
	results = mysql_conn.query("SELECT * FROM safeEntry ORDER BY crowd_level ASC;")
	mysql_conn.close

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

	puts "BOOT PROGRAM LOADED!"
end

def update
	puts "LOADING UPDATE SEQUENCE!"
	
	crowd_limit = []

	#Query safeEntry for no. of entries
	results = mysql_conn.query("SELECT crowd_limit FROM safeEntry;")
	mysql_conn.close
	results.each do |row|
		crowd_limit << row["crowd_limit"].to_s
	end

	#crowd_level updated with random number between 0 to 1000
	for i in 0...results.count + 1
		if crowd_limit[i] == "5000"
			rand_num = rand 5000
		elsif crowd_limit[i] == "10000"
			rand_num = rand 10000
		else
			rand_num = rand 15000
		end

		mysql_conn.query("UPDATE safeEntry SET crowd_level=" + rand_num.to_s + " WHERE store_id=" + (i + 1).to_s + ";")
		mysql_conn.close
	end
	
	puts "UPDATE SEQUENCE LOADED!"
end

def insert
	puts "LOADING INSERT SEQUENCE!"
	
	id_num = mysql_conn.query("SELECT crowd_limit FROM safeEntry;")
	mysql_conn.close

	if $location_name.to_s.empty? != TRUE || $limit.to_s.empty? != TRUE
		mysql_conn.query("INSERT INTO safeEntry (store_id, store_address, crowd_level , crowd_limit) VALUES( " + (id_num.count + 1).to_s + ", '"  + $location_name.to_s + "', 0, " + $limit.to_s  + ");")
		mysql_conn.close()
                puts "STATEMENT HAS BEEN QUERIED!"
        end

	puts "INSERT SEQUENCE LOADED!"
end

def delete
	puts "LOADING DELETE SEQUENCE!"

	old_count = mysql_conn.query("SELECT COUNT(*) FROM safeEntry;")
	mysql_conn.close

	if $store_id.to_s.empty? != TRUE
		mysql_conn.query("DELETE FROM safeEntry WHERE store_id=" + $store_id.to_s + ";")
		puts "DELETE STATEMENT HAS BEEN QUERIED!"
		new_count = mysql_conn.query("SELECT COUNT(*) FROM safeEntry;")

	end
	
        mysql_conn.close	
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
					<p>A Singapore Governement Agency Website</p>
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
				<p>Welcome to the Safe Entry Management Portal(SEMP)! Here you'll be able to access the crowd levels of various shopping malls and buildings. Simply click on the <b>Refresh</b> to update the page with new records. Click <b>Insert</b> to add a new building to the list! And click <b>Delete</b> to remove a building from the list!<br></br><b><i> #LET'S DO OUR PART!</i></b><br><b><i> #SGUNITED!</i></b></br></p>
				<br>
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

		</head>
		<body>
			<header>
				<div class='sg_gov'>
                                        <p>A Singapore Governement Agency Website</p>
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
				<h1>Welcome to Safe Entry Insert Page</h1>
				<p>Please state the name of the store followed by the crowd limit!</p>
				<form method='post' action='/runInsert'>
					Store Name: <input type='text' name='location'><br></br>
					Crowd Limits: <input type='text' name='limit'><br></br>					
					<button type='submit' value='Submit'>Submit</button>
					<a href='/index'>
						<input type='button' value='Back'>
					</a>
				</form>
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

                </head>
		<body>
			<header>
                                <div class='sg_gov'>
                                        <p>A Singapore Governement Agency Website</p>
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
				<h2>Welcome to Safe Entry Delete Page</h2>
                                <p>Refer to the table below and key in the respective Store ID in the input box!</p>
				#{$xm}
				<br>
                                <form method='post' name='Form' onSubmit='return validateForm()' action='/runDelete'>
                                        Store ID: <input type='text' name='store_id'><br></br></br>
                                        <button type='submit' value='Submit'>Submit</button>
                                        <a href='/index'>
                                                <input type='button' value='Back'>
                                        </a>
                                </form>
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

                </head>
                <body>
                        <header>
                                <div class='sg_gov'>
                                        <p>A Singapore Governement Agency Website</p>
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
				<h1>About</h1>
				<br>
                                <h3>What is Safe Entry?</h3>
				<p>SafeEntry is a national digital check-in system that logs the NRIC/FINs and mobile numbers of individuals visiting hotspots, workplaces of essential services, as well as selected public venues to prevent and control the transmission of COVID-19 through activities such as contact tracing and identification of COVID-19 clusters. Individuals can choose to check in/out from SafeEntry at entry/exit points using any of the following methods:
(a) Scan QR code: Use the SingPass Mobile app, TraceTogether app, your mobile phone’s camera function or a recommended QR scanner app to scan a QR code and submit your personal particulars; or
(b) Scan ID card: Present an identification card barcode (e.g. NRIC, Passion card, Pioneer Generation card, Merdeka Generation card, driver’s licence, Transitlink concession card, student pass, work permit, SingPass Mobile app, TraceTogether app) to be scanned by staff; or
(c) Select from a list of nearby locations: Use the SingPass Mobile app’s ‘SafeEntry Check-In’ function to select a location and check in.</p>
				</br>
                                <h3>Why is Safe Entry being deployed to more places?</h3>
                                <p>As more activities and services gradually resume following the circuit breaker period, it is important that efforts to prevent and control the transmission of COVID-19 such as contact tracing and identification of COVID-19 clusters can be done quickly to limit the risk of further community transmission. SafeEntry helps support and quicken these efforts to prevent and control the incidence or transmission of COVID-19 as it provides authorities with a record of individuals who enter and exit places. The records will reduce the time needed to identify potential close contacts of COVID-19 patients and potential COVID-19 clusters. This is important so that we can continue advancing towards fewer restrictions on our movements, and our daily lives</p>
				<br>
				<h3>Why do we need to use SafeEntry instead of existing vendor management systems?</h3>
				<p>The use of SafeEntry is mandatory because a common system used by all establishments would allow data to be made available to MOH quickly, so as to facilitate efforts to prevent and control the transmission of COVID-19 through activities such as contact tracing and identification of COVID-19 clusters. SafeEntry allows information of visitors and employees who may have come into contact with COVID-19 cases to be sent to the authorities automatically. Contact data collected by SafeEntry is only used by authorised personnel, and stringent measures are in place to safeguard the data in accordance with the Government’s data security standards.</p>
				</br>
                                <h3>Can I use an alternative visitor management system instead of SafeEntry?</h3>
                                <p>From 12 May onwards, businesses are required to use SafeEntry to collect entry information of employees and visitors on their premises. Businesses that need to retain the use of their current system for the collection of data that are not required in the SafeEntry system (e.g. purpose of visit, employee’s ID number) are required to implement SafeEntry on top of their existing system. To cater to visitors who are not able to scan QR codes or do not have their identification cards with them, businesses are advised to also assist individuals to check in through the manual entry function in SafeEntry using their NRIC, or the webform in SafeEntry with the QR code using any available device.</p>
                                <br>
                                <h3>What happens if safeEntry breaks down? Is there flexibility in the enforcement of SafeEntry?</h3>
				<p>Businesses should tap on the alternate mode of SafeEntry in the unlikely event that their preferred mode breaks down, i.e. use SafeEntry QR as back-up if SafeEntry NRIC is the preferred mode, and vice versa. Businesses may do so by setting up the alternate mode at <a href='https://www.SafeEntry.gov.sg'/>https://www.SafeEntry.gov.sg</a>. SafeEntry does not recommend hard copy form filling as a back-up.

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
                                        <p>A Singapore Governement Agency Website</p>
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
				<p> Click the [Back] button to return to the index page.<br></br>
				<a href='/index'>
					<input type='submit' value='Back'/>
				</a>
			</section>
		</body>
	</html>
	"
end
