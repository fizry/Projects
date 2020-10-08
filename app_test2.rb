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
post "/runUpdate" do
	update
	redirect "/index"
end

get "/runInsert" do
	insert_template
end

post "/runInsert" do
	$location_name = params[:location]
	insert
	$location_name + " added! "
	back_to_index
end

def mysql_client
	puts "LOADING BOOT PROGRAM!"
	table_arr = []

	#Query results from safeEntry
	results = $client.query("SELECT * FROM safeEntry ORDER BY crowd_level ASC;")

	#Store each result entry into dictionary before being stored in table_arr
	results.each do |row|
		table_arr << {"Location ID" => row["store_id"].to_s, "Location" => row["store_address"], "Crowd Level" => row["crowd_level"].to_s}
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
	
	#Query safeEntry for no. of entries
	results = $client.query("SELECT * FROM safeEntry;")

	#crowd_level updated with random number between 0 to 1000
	for i in 1..results.count
		rand_num = rand 2000
		$client.query("UPDATE safeEntry SET crowd_level=" + rand_num.to_s + " WHERE store_id=" + i.to_s + ";")
	end
	
	#Pause the program for 5 seconds
	#sleep 3

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
                        table, td, tr, th{border: 1px solid black;width: 500px;text-align: center;}
                </style>
                <body>
			<img src='images/safeEntry.jpg' alt='Safe Entry Logo' width='200' height='70'/>
                        <p>Welcome to the Safe Entry Management Portal. From this portal you'll be able to add, delete and refresh the crowd levels at different locations in Singapore.</p>
                        <p>Click the [REFRESH] button to refresh the table!</p>
                        <form method='post' action='/runUpdate'>
                                <button type='submit' value='Submit'>REFRESH</button>
                        </form>
                        <p>Click the [INSERT] button to add a new location!</>
                        <form method='get' action='/runInsert'>
                                <button type='submit' value='Submit'>INSERT</button>
                        </form>
                        <br>
                        #{$xm}
                        </br>
                        #{"Last Updated: " + Time.now.ctime}
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

def back_to_index
	"
	<html>
		<body>
			<p> Click the [Back] button to return to the index page.<br>
			<a href='/index'>
				<input type='submit' value='Back'/>
			</a>
			</br>
		</body>
	</html>
	"
end
