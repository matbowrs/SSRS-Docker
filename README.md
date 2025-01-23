# SQL Server Reporting Services in Docker

Creates a fresh install of SSRS in a container - pretty useful for dev / test - not for production use!

This is an extension of the great work done by:

- https://github.com/phola
- https://github.com/SaViGnAnO

I forked my own version to make it compatible with my needs.

## Run it

First, please ensure that you download SQL Server 2019. You can download the "Developer" version here: https://go.microsoft.com/fwlink/?linkid=866662f. The download will start immediately. This is a *.exe*! 

Next, run the downloaded file. You'll see a screen that says "Select an installation type". Go to "Download Media". Next, you'll be asked which package you'd like to download. Since we are using both a *.box* and a *.exe* file in our Dockerfile, we want to download the *CAB* version. 

Lastly, select a path to install to. Once that is installed, you can move those 2 files, the .exe and the .box, to the local directory where the Dockerfile is found. 

Now you can build the image:
```
docker build -t ssrs2019 .
```

This sample uses servercore:ltsc2019 as a parent image. Find out more here: 

https://hub.docker.com/r/microsoft/windows-servercore

In addtion it accepts two more env variables: </br>

- **ssrs_user**: Name of a new admin user that will be created to login to report server
- **ssrs_password**: Sets the password for the admin user

Example:

```
docker run -d -p 1433:1433 -p 80:80 -v C:/temp/:C:/temp/ -e sa_password=<YOUR SA PASSWORD> -e ACCEPT_EULA=Y -e ssrs_user=SSRSAdmin -e ssrs_password=<YOUR SSRSAdmin PASSWORD> --memory 6048mb phola/ssrs
```

Then access SSRS at http://localhost/reports_ssrs and log in using the user specified for *ssrs_user*, SSRSAdmin, or sa, for example.

## Tips

- **-p 80:80** to access report manager in browser
- **--memory 6048mb** to bump RAM

## Disclaimers

SSRS is defintely not supported in containers..

## Credits

- [Complete automated configuration of SQL Server 2017 Reporting Services - Sven Aelterman](https://svenaelterman.wordpress.com/2018/01/03/complete-automated-configuration-of-sql-server-2017-reporting-services/)

## License

MIT license. See the [LICENSE file](LICENSE) for more details.
