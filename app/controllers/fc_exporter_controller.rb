# Dependencies to run the program
# 1> rmagick
# 2> json
require "RMagick" 
require 'rubygems'
require 'json'
class FcExporterController < ApplicationController
  
  # following line is required thus the controller can be called from javascript without any key authentication
  protect_from_forgery with: :null_session 
  
  # settings variable declaration begins
  SAVE_PATH = "ExportedImages/"
  # settings variable declaration ends

  # this method should be called as http://localhost:<PORT-NUMBER(eg. 3000)>/fc_exporter/init/ from javascript
  def init
  	

  	checkAndCreateDirectories([SAVE_PATH])

  	requestObject = parseRequestParams(request.POST)
  	stream = requestObject['stream']
  	if requestObject['imageData'] != ""
  		stream = stichImageToSVG(stream, requestObject['imageData'])		
  	end
  	convertSVGtoImageOrPdf(stream, requestObject['exportFileName'] ,requestObject['exportFormat'])	
  end

  # From here all the declared members are private in nature
  private

  # this function check for the directories needed to export image
  # if not present then it creates the directories
  def checkAndCreateDirectories(directoriesNameArray)
  	directoriesNameArray.each do |directoryName|
  		if !File.directory?(directoryName) # if the directory doesn't exists create that
  			begin
  				Dir.mkdir directoryName
  			rescue
  				raiseError("403") # raising error if directory cann't be created
  			end	
  		end	
  	end	
  end	

  # This function purse the request and create the request Data object
  def parseRequestParams(requestData)
  	# Following values are expected to have from request stream
  	stream = "" # expected to hold the SVG string coming from the chart
  	imageData = "" # if the request contains raw image data then those will go here
  	parametersArray = [] # holds the parameters
  	width = 0 # holds the width of exported image
  	height = 0 # holds the height of exported image
  	exportFileName = "" # holds the name of the exported file
  	exportFormat = "" # holds the format of the exported files
  	exportAction = ""

  	stream = requestData['stream']
  	if requestData['encodedImgData']
  		imageData = requestData['encodedImgData']
  	end
  	width = requestData['meta_width']
  	height = requestData['meta_height']
  	parametersArray = requestData['parameters'].split("|")
  	exportFileName = parametersArray[0].split("=").last
  	exportFormat = parametersArray[1].split("=").last
  	exportAction = parametersArray[2].split("=").last
  	
  	# preparing the request object
  	requestObject = {
  		'stream' => stream, 
  		'imageData' => imageData, 
  		'width' => width, 
  		'height' => height, 
  		'exportFileName' => exportFileName, 
  		'exportFormat' => exportFormat, 
  		'exportAction' => exportAction
  	}

  	return requestObject
  end	

  # this function replaces the image href with image data
  def stichImageToSVG(svgString, imageData)
  	
  	imageDataArray = JSON.parse(imageData) # parsing the image data object
  	keys = imageDataArray.keys # holds the keys like image_1, image_2 etc  
  	matches = /xlink:href\s*=\s*"([^"]*)"/.match(svgString).captures # matches array holds the physical paths of images lies in the SVG
  	
  	# looping through all of the matches
  	matches.each do |match|
	    imageName = match.split("/").last.split(".").first
	    imageData = ""
		
		# looping through the images of json data	
		keys.each do |key|
	    	if imageDataArray[key]['name'] == imageName
	    		imageData = imageDataArray[key]['encodedData']
	    		break
	    	end	
		end
		svgString = svgString.sub(match, imageData); # replacing the image href with image data
	end

  	return svgString
	
  end	

  # this method raise the error based on the error code
  def raiseError(errorCode)
  	errorArray = {
  			'100' => " Insufficient data.", 
  			'101' => " Width/height not provided.", 
  			'102' => " Insufficient export parameters.", 
  			'400' => " Bad request.", 
  			'401' => " Unauthorized access.", 
  			'403' => " Directory write access forbidden.", 
  			'404' => " Export Resource not found."
  		}
  end	

  # this function sends the provided file as downloadable to the browser
  def sendFileToDownload(fileName)
  	send_file(fileName)
  end	

  # This function coverts the provided SVG string to image or pdf file
  def convertSVGtoImageOrPdf(svgString, exportFileName, exportFileFormat)
  	completeFileName = SAVE_PATH+exportFileName+"."+exportFileFormat
  	if !File.exist?('image.jpg') 
	  	if exportFileFormat != "svg"
		  	img = Magick::Image.from_blob(svgString) {
			  self.format = 'SVG'
			}
			begin
				img[0].write(completeFileName)
			rescue
				raiseError("403") # raising error if image cannot be created	
			end	
		else
			begin
				file = File.open(completeFileName, 'w')
				file.write(svgString) 
				file.close()
			rescue
				raiseError("403") # raising error if file cannot be created	
			end
		end
		sendFileToDownload(completeFileName)
	end	
  end	
end


# Installing rmagick in ubuntu
# => First, check that the universe repository is enabled by inspecting '/etc/apt/sources.list' with your favourite editor.

# => You will need to use sudo to ensure that you have permissions to edit the file.

# => If universe is not included then modify the file so that it does.

# => deb http://us.archive.ubuntu.com/ubuntu precise main universe
# => After any changes you should run this command to update your system.

# => sudo apt-get update
# => You can now install the package like this.

# => Install librmagick-ruby
# => sudo apt-get install librmagick-ruby

