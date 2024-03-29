#some stuff
import serial
import cv2
from twilio.rest import Client
import io, glob, os, sys, time, uuid
from azure.cognitiveservices.vision.face import FaceClient
from msrest.authentication import CognitiveServicesCredentials
from azure.cognitiveservices.vision.face.models import TrainingStatusType, Person, SnapshotObjectType, OperationStatusType

import serial
import cv2
from twilio.rest import Client


twilio_account_sid = '';
twilio_auth_token = '';
client = Client(twilio_account_sid, twilio_auth_token);
KEY = ''
ENDPOINT = ''
 
# Create an authenticated FaceClient.
face_client = FaceClient(ENDPOINT, CognitiveServicesCredentials(KEY))
 
# Used in the Person Group Operations
PERSON_GROUP_ID = "authorized"
TARGET_PERSON_GROUP_ID = str(uuid.uuid4()) # assign a random ID (or name it anything)
vc = cv2.VideoCapture(0)
arduinoData = serial.Serial('/dev/tty96B0',9600, timeout=1.5);
i = 0;
print "Ready for input"
while True:
    line = arduinoData.readline();
    i = int(line);
    if i == 1:
        print "Input detected"
        ret, frame = vc.read()
        cv2.imwrite("test.png", frame);
        #IDENTIFYING
 
        # Reference image for testing against
        group_photo = 'test.png'
        IMAGES_FOLDER = os.path.join(os.path.dirname(os.path.realpath(__file__)))
 
        # Get test image
        test_image_array = glob.glob(os.path.join(IMAGES_FOLDER, group_photo))
        image = open(test_image_array[0], 'r+b')
 
        # Detect faces
        print "Detecting faces..."
        face_ids = []
        faces = face_client.face.detect_with_stream(image)
        for face in faces:
            face_ids.append(face.face_id)
 
        # Identify faces
        print 'Identifying faces in {}'.format(PERSON_GROUP_ID)
        results = face_client.face.identify(face_ids, PERSON_GROUP_ID)
        for person in results:
            if person.candidates:
                nameOfFound = "Unknown"
                IDs = [guy for guy in face_client.person_group_person.list(person_group_id=PERSON_GROUP_ID)]
                for i in IDs:
                    if i.person_id == person.candidates[0].person_id:
                        nameOfFound = i.name
                        print 'Person is identified as {} with a confidence of {}.'.format(nameOfFound, person.candidates[0].confidence)
                        client.messages \
                              .create(
                                  body=nameOfFound + " is at your door.",
                                  from_="",
                                  to=""
                              )
            else:
                client.messages \
                      .create(
                          body="Unknown",
                          from_="",
                          to=""
                      )
        break
    print(line);
vc.release();
