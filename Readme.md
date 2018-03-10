# About
A implementation for Assignment 2 COMP 327 Mobile Computing developed using swift.
It is the map for present artworks info located in Uni. of Liverpool according to users' proximity.
I have to say the course is simple and boring one as nothing surprised on Mobile Computing :)

# Backend Required
Currently it uses [this link](https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks2&lastUpdate=)  
for artwork data. Notice the *lastUpdate* parameter takes date in form of "YYYY-MM-dd" (e.g. 2017-11-10),
which representing the returned results should be updated later than the given date.

The format of it looks like:
```json  
{  
    "artworks":[  
        {  
            "id":"34",
            "title":"Entrance",
            "artist":"Maurice Cockrill",
            "yearOfWork":"1975",
            "Information":"Hyper-realistic style painting of the artist's girlfriend at the time outside what was the entrance to the Arts Reading Room.  Cockrill was a lecturer in fine art at Liverpool Polytechnic 1967-80 and Keeper of the Royal Academy of Arts, 2004.  He has been described as 'one of the most expressive painters of the 1980s and 1990s'.",
            "lat":"53.40191",
            "long":"-2.96588",
            "locationNotes":"Entrance to the Rendall Building",
            "fileName":"Entrance by Maurice Cockrill.jpg",
            "lastModified":"2017-11-22 12:22:31"
        },
        {
        }
      ]
}
```  

The images comes from
[Here](https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/),
the name of images should keep same accordingly with those in *fileName* field in the JSON returned from the first link in this section above.  
