import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as express from "express";

const app = admin.initializeApp();
const firestore = app.firestore();

const LINK_MAX_LIFETIME = 3.6e7; // 10 hours

const router = express();

async function getLink(req: express.Request, res: express.Response) {
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
}

router.get("/link", getLink);
router.get("/", getLink);

export const link = functions.region("europe-west3").https.onRequest(router);

function hasLinkExpired(data: admin.firestore.DocumentData): boolean {
    return data["created_at"] + LINK_MAX_LIFETIME <= Date.now();
}

export const linkExpiryCheck = functions
    .region("europe-west3")
    .pubsub
    .schedule("every 24 hours")
    .onRun(async () => {
        const links = await firestore.collection("links").get();
        for (const link of links.docs) {
            if (!hasLinkExpired(link.data())) continue;
            link.ref.delete();
        }
    });
