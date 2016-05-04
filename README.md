# svuhelper-backend
An application that provides an API (HTTP/JSON) around SVU (Syrian Virtual University) website, by scraping their HTML.
*Read more on [Web scraping](https://en.wikipedia.org/wiki/Web_scraping)*

# You need
* [Node.js](https://nodejs.org/en/)
* [MongoDB](https://www.mongodb.org/)
* [CoffeeScript](http://coffeescript.org/)

# How we do it... (+Node.js modules used)
* [express](https://www.npmjs.com/package/express) is used as our framework
* [body-parser](https://www.npmjs.com/package/body-parser) is used to parse incoming json bodies (an express middleware)
* We use [request](https://www.npmjs.com/package/request) to execute requests against SVU servers, on behalf of the user:
  * On login request, we get username/password and send them to get a session token from the university website
  * We use the session token on subsequent request to other pages
* When we get the response (html page from SVU servers), we convert the page to utf-8 with the help of [encoding](https://www.npmjs.com/package/encoding), and then select valuable html bits using [cheerio](https://www.npmjs.com/package/cheerio)
* We use [mongoose](https://www.npmjs.com/package/mongoose) models to read/write from MongoDB
* We also use [async], [lodash], and [debug].
