# base-image-for-shinymenu
Repo contains only the docker file required to build the base image for simplest application of shinymenu app

This is a docker image based on Ubuntu 20 and includes:

  Docker
  R-base-dev
  Shiny-Server
  MySql (MariaDB)
  Nginx
  Certbot
  Required R packages ('shiny', 'shinyWidgets' ,'DT', 'RMariaDB', 'DBI', 'shinyalert', 'qrcode', 'xtable')

To implement the simplest version of the shinymenu suite, create (or use the available) dockerfile pulling from this image and then:
  download apps (customer and venue end)
  download venue info and price list from cloud storage and copy into correct app folders
  put apps into the shiny server location
  build new image for specific venue
  run image

To run:
git clone https://github.com/matty8salisbury/base-image-for-shinymenu.git
cd base-image-for-shinymenu
./create-shinymenu-base-docker-image.sh
