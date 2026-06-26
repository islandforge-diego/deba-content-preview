# Client Content Review Tool

Mobile-friendly review pages where clients preview their scheduled social content
(feed posts + an Instagram Stories calendar). One repo, many clients, served on GitHub Pages.

## Live
- Root `/` redirects to the default client (`clients/deba/`).
- Each client: `https://islandforge-diego.github.io/deba-content-preview/clients/<slug>/`

## How it works
- `clients/<slug>/config.json` — all of a client's data (brand colors, banner, feed posts, stories).
- `clients/<slug>/stories/` — that client's story-card images.
- `generate.py` — reads every `clients/*/config.json` and writes each `clients/<slug>/index.html`, plus the root redirect.

## Update a client
1. Edit `clients/<slug>/config.json` (and drop any new images in `clients/<slug>/stories/`).
2. `python3 generate.py`
3. `git add -A && git commit -m "update <slug>" && git push`
GitHub Pages serves the new HTML within a minute.

## Add a new client
1. `mkdir -p clients/<slug>/stories`
2. Create `clients/<slug>/config.json` (copy Deba's as a template; change `slug`, `name`, `title`, `theme` colors, `banner`, `footer`, `feed`, `stories`).
3. `python3 generate.py && git add -A && git commit -m "add <slug>" && git push`
4. Share `…/clients/<slug>/` with the client.
To make a new client the default landing page, change `DEFAULT_CLIENT` in `generate.py`.

## config.json shape (short)
```
{
  "slug": "deba", "name": "...", "title": "...", "range_label": "Jun 23–28",
  "feed_time": "3:00 PM CT",
  "theme": {"accent":"#1f6f54","soft":"#e8f1ec","soft_border":"#cfe2d8","accent_text":"#16503c","story_bg":"#0d5f6e"},
  "banner": "html allowed", "footer": "text",
  "stories": {"channel":"handle","month_label":"June 2026","year":2026,"month":6,
              "items":[{"day":23,"dow":"Tue","time":"2:00 PM CT","title":"...","sticker":"...","img":"stories/x.png"}]},
  "feed": [{"date":"Tue · Jun 23","title":"...","chips":["Instagram"],
            "media":{"type":"gallery","images":["url"]} | {"type":"video","poster":"url","src":"url"},
            "caps":[["Instagram","caption text"]]}]
}
```

## Media hosting on AWS S3 (replaces Cloudinary + WeTransfer)
Two ways to get a media URL for Buffer/Canva:

**Local (ad-hoc):** `scripts/push_to_s3.sh`
```
brew install awscli ffmpeg
aws configure
printf 'S3_BUCKET=your-bucket\nAWS_REGION=us-east-1\n' >> ~/.deba_s3
./scripts/push_to_s3.sh clip.mov --mp4        # transcode + upload, prints public URL
./scripts/push_to_s3.sh report.pdf --share    # 7-day presigned link (private)
```

**Automated (no Mac needed):** the **Upload media to S3** GitHub Action
(`.github/workflows/s3-upload.yml`). Run it from the repo's Actions tab with a source URL +
destination key; it fetches, optionally transcodes, uploads, and prints the public URL.
Add these repo **Secrets** first (Settings → Secrets and variables → Actions):
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `S3_BUCKET`.

> Bucket access: for public media use a public-read bucket policy; for private shares use presigned URLs. Never commit AWS keys — use `aws configure` locally and repo Secrets in Actions.
