import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const app = admin.initializeApp();
const firestore = app.firestore();

const LINK_MAX_LIFETIME = 3.6e7; // 10 hours

export const link = functions
    .region("europe-west1")
    .https
    .onRequest(async (req, res) => {
        if (req.query.id === undefined) {
            res.status(400).send("Please specify 'id' in the url!");
            return;
        }

        const documentId = req.query.id.toString();
        const link = await firestore
            .collection("links")
            .doc(documentId)
            .get()
            .catch(() => {
                res.status(404).send("No link found");
                return undefined;
            });
        if (link === undefined) return;

        const data = link.data();
        if (data === undefined) {
            res.status(400).send("The requested document does not have data!");
            return;
        }

        if (hasLinkExpired(data)) {
            await link.ref.delete();
            res.status(404).send("No link found");
            return;
        }

        delete data["created_at"];
        res.status(200).json(data);
    });

function hasLinkExpired(data: admin.firestore.DocumentData): boolean {
    return data["created_at"] + LINK_MAX_LIFETIME <= Date.now();
}
