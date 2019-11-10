import io, glob, os, sys, time, uuid
from azure.cognitiveservices.vision.face import FaceClient
from msrest.authentication import CognitiveServicesCredentials
from azure.cognitiveservices.vision.face.models import TrainingStatusType, Person, SnapshotObjectType, OperationStatusType

import firebase_admin
from firebase_admin import credentials
from firebase_admin import db


cred = credentials.Certificate("/Users/Naveen/Desktop/Python/facial-recog/hacknjit-9a9be-firebase-adminsdk-2j61m-5d5bac921b.json")
firebase_admin.initialize_app(cred, {'databaseURL':'https://hacknjit-9a9be.firebaseio.com/'})
root = db.reference()

KEY = os.environ['FACE_SUBSCRIPTION_KEY']
ENDPOINT = os.environ['FACE_ENDPOINT']

# Create an authenticated FaceClient.
face_client = FaceClient(ENDPOINT, CognitiveServicesCredentials(KEY))

# Used in the Person Group Operations
PERSON_GROUP_ID = "authorized"
TARGET_PERSON_GROUP_ID = str(uuid.uuid4()) # assign a random ID (or name it anything)

choice = raw_input("Train (t), Identify (i), Delete (d), Create Group (c), Delete Group (q), List(l), or Exit (anything else)?\n")


while True:
    if choice == 't':
        # TRAINING

        # Find all jpeg images the person
        users = root.child('Users').get()

        people = {}
        for i in users:
            print "Person: "
            print i
            personTBR = face_client.person_group_person.create(PERSON_GROUP_ID, i)
            people[i] = root.child("Users").child(i).order_by_key().get()

            for val, url in people[i].items():
                if url != None:
                    face_client.person_group_person.add_face_from_url(PERSON_GROUP_ID, personTBR.person_id, url)

            print 'Training the person group...'
            # Train the person group
            face_client.person_group.train(PERSON_GROUP_ID)

            while (True):
                training_status = face_client.person_group.get_training_status(PERSON_GROUP_ID)
                print "Training status: {}.".format(training_status.status)
                print "\n"
                if (training_status.status is TrainingStatusType.succeeded):
                    break
                elif (training_status.status is TrainingStatusType.failed):
                    sys.exit('Training the person group has failed.')
                time.sleep(5)



    elif choice == 'i':
        #IDENTIFYING

        # Reference image for testing against
        group_photo = 'test2.png'
        IMAGES_FOLDER = os.path.join(os.path.dirname(os.path.realpath(__file__)))

        # Get test image
        test_image_array = glob.glob(os.path.join(IMAGES_FOLDER, group_photo))
        image = open(test_image_array[0], 'r+b')

        # Detect faces
        face_ids = []
        faces = face_client.face.detect_with_stream(image)
        for face in faces:
            face_ids.append(face.face_id)

        # Identify faces
        results = face_client.face.identify(face_ids, PERSON_GROUP_ID)
        print 'Identifying faces in {}'.format(PERSON_GROUP_ID)

        for person in results:
            if person.candidates:
                nameOfFound = "Unknown"
                IDs = [guy for guy in face_client.person_group_person.list(person_group_id=PERSON_GROUP_ID)]
                for i in IDs:
                    if i.person_id == person.candidates[0].person_id:
                        nameOfFound = i.name
                print 'Person is identified as {} with a confidence of {}.'.format(nameOfFound, person.candidates[0].confidence)
            else:
                print "Unknown Person"

    elif choice == 'd':
        # DELETING PERSON FROM GROUP
        names = [person for person in face_client.person_group_person.list(person_group_id=PERSON_GROUP_ID)]
        nameOfPerson = raw_input("Name of person to be removed?\n")
        for i in names:
            if i.name == nameOfPerson:
                face_client.person_group_person.delete(person_group_id=PERSON_GROUP_ID, person_id=i.person_id)
                print "Deleted {} from person group {}.".format(nameOfPerson,PERSON_GROUP_ID)
                print "\n"


    elif choice == 'c':
        # Create empty Person Group

        print 'Person group: ' + PERSON_GROUP_ID
        face_client.person_group.create(person_group_id=PERSON_GROUP_ID, name=PERSON_GROUP_ID)

    elif choice == 'q':
        # Delete the authorized group.
        face_client.person_group.delete(person_group_id=PERSON_GROUP_ID)

    elif choice == "l":
        # Lists all authorized people

        names = [person for person in face_client.person_group_person.list(person_group_id=PERSON_GROUP_ID)]
        for i in names:
            print i.name

    else:
        print "Exiting"
        break;

    choice = raw_input("Train (t), Identify (i), Delete (d), Create Group (c), Delete Group (q) or List(l)?\n")