# RUHome?

Inspiration
We were inspired by the idea of having a ring-type doorbell with a secure and convenient facial recognition to grant access or alert the user if an unrecognized face is detected.

## What it does
A doorbell that grants access based on who it recognizes via facial recognition for pizza delivery people. For example, if Dominos had the app, they would take pictures of their delivery people and when they come to deliver the pizza, they will ring the doorbell which will click an image from the webcam and then proceed to check if that person is, in fact, the pizza delivery person by using Azure facial recognition. If the person is the right person, then Twilio will send you a text message saying "your pizza is here", and if it isn't the right person, you will get a message saying there is an intruder. Since sometimes people don't hear the doorbell, instead of having the pizza delivery person waiting outside in the cold, we will simply notify you if they are there.

## How we built it
Mobile App using Flutter. SMS Integration using Twilio. Facial Recognition using Microsoft Azure. Backend/Database using Google Firebase.

## Challenges we ran into
Combining facial recognition portion with the hardware portion. Sending an image to the user of the person at the door using Twilio due to a lack of Twilio credit.

## Accomplishments that we're proud of
Integrating many features in 24 hours and still getting at least 4 hours of sleep

## What we learned
How to skateboard How to use Azure, Flutter, Twilio

## What's next for RU Home
Allow multiple users to use this app at the same time
