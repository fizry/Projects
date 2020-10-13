#Load required modules
require 'sinatra'
require 'sinatra/reloader'
require 'mysql2'
require 'builder'

#Global variable set to database connection
$client = Mysql2::Client.new(
                :host => '127.0.0.1',
                :username => 'root',
                :password => 'toor',
                :database => 'INTERNSHIP',
                :encoding => 'utf8'
        )

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
	insert
	$location_name + " added! "
	back_to_index
end

#Delete template is retrieved and displayed
get "/runDelete" do
	delete_template
end


def mysql_client
	puts "LOADING BOOT PROGRAM!"
	table_arr = []

	#Query results from safeEntry
	results = $client.query("SELECT * FROM safeEntry ORDER BY crowd_level ASC;")

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
	results = $client.query("SELECT crowd_limit FROM safeEntry;")
	results.each do |row|
		crowd_limit << row["crowd_limit"].to_s
	end

	#crowd_level updated with random number between 0 to 1000
	for i in 0...results.count
		if crowd_limit[i] == "5000"
			rand_num = rand 5000
		else
			rand_num = rand 10000
		end

		$client.query("UPDATE safeEntry SET crowd_level=" + rand_num.to_s + " WHERE store_id=" + i.to_s + ";")
	end

	puts "UPDATE SEQUENCE LOADED!"
end

def insert
	puts "LOADING INSERT SEQUENCE!"
        if $location_name.to_s.empty? != TRUE
                $client.query("INSERT INTO safeEntry (crowd_level, store_address) VALUES(0, '" + $location_name.to_s + "');")
                puts "STATEMENT HAS BEEN QUERIED!"
        end
	puts "INSERT SEQUENCE LOADED!"
end

def index_template
        "
        <html>
                <head>
                </head>
                <style>
			table, td, tr, th{border: 1px solid black; width: 550px; text-align: center; background-color: #FFF0F5;}
			header {display: block; background-color: #DCDCDC;}
			div.image {float: left; display: inline-block; background-color: #FFFFFF;}
			ul {display: inline-block; list-style-type: none; background-color: #FFFFFF;}
			li {float: right}
			li a {display: block; color: black; text-align: center; padding: 14px 16px; text-decoration: none;}
			bottom-body {display: block; background-color: #FFF0F5;}
                </style>
                <body>
			<header>
				<p>A Singapore Governement Agency Website</p>
			</header>
			<div class='image'>
				<img src='https://www.ndi-api.gov.sg/assets/img/safe-entry/SafeEntry_logo_inline.png' alt='Safe Entry Logo' width=300 height=60/>
			</div>
			<ul>
				<li><a href='/runUpdate'>Refresh</a></li>
				<li><a href='/runInsert'>Insert</a></li>
				<li><a href='/runDelete'>Delete</a></li>
			</ul>
			<br>
			<bottom-body>
				#{$xm}
				<br>
                		#{'Last Updated: ' + Time.now.ctime}
			</bottom-body>
			</br></br>
                </body>
        </html>
        "
end

def insert_template
	"
	<html>
		<body>
			<h1>Welcome to Safe Entry Insert Page</h1>
			<p>Please enter the name of the building and click [Submit] when you are ready!</p>
			<form method='post' action='/runInsert'>
				Location Name: <input type='text' name='location'>
				<button type='submit' value='Submit'>Submit</button>
			</form>
			<a href='/index'>
				<input type='submit' value='Back'/>
			</a>
		</body>
	</html>
	"
end

def delete_template
	"
	<html>
		<body>
			<h1>Welcome to Safe Entry Delete Page</h1>
			<p style='color:red'>I'm Sorry This Page Is Currently Under Construction! We Apologize For Any Inconveniences Caused</p><br>
			<a href='/index'>
				<input type='submit' value='Back'/>
			</a>
			</br>
		</body>
	</html>
	"
end

def back_to_index
	"
	<html>
		<body>
			<p> Click the [Back] button to return to the index page.<br></br>
			<a href='/index'>
				<input type='submit' value='Back'/>
			</a>
		</body>
	</html>
	"
end
