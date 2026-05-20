# uuid_service

This project is inspired by a HackerNews comment:

> Ask HN: We just had an actual UUID v4 collision...
> “Funny story no one will believe, but it’s true. A good friend of mine joined a startup as CTO 10 years ago, high growth phase, maybe 200 devs… In his first week he discovered the company had a microservice for generating new UUIDs. One endpoint with its own dedicated team of 3 engineers …including a database guy (the plot thickens). Other teams were instructed to call this service every time they needed a new ‘safe’ UUID. My pal asked wtf. It turned out this service had its own DB to store every previously issued UUID. Requests were handled as follows: it would generate a UUID, then ‘validate’ it by checking its own database to ensure the newly generated UUID didn’t match any previously generated UUIDs, then insert it, then return it to the client. Peace of mind I guess. The team had its own kanban board and sprints.” 

The purpose of this project is to implement this service.

# Architecture 

- Uses AWS Lambda, accessible via AWS API Gateway on a corporate VPC
- Uses Dynamo DB
- Uses OpenTofu for Infrastructure-as-code
- Includes a post-deploy verification test that verifies it is working




