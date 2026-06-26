#!/usr/bin/env bash
# push_to_s3.sh — upload a local file to S3 and print a shareable URL.
# Replaces Cloudinary (media hosting for Buffer/Canva) and WeTransfer (file sharing).
#
# One-time setup on your Mac:
#   1) brew install awscli ffmpeg          # ffmpeg only needed for --mp4
#   2) aws configure                       # paste your AWS Access Key + Secret + region
#   3) Set your bucket once:  echo 'S3_BUCKET=your-bucket-name' >> ~/.deba_s3 ; echo 'AWS_REGION=us-east-1' >> ~/.deba_s3
#      (optional) echo 'CLOUDFRONT_DOMAIN=cdn.yourdomain.com' >> ~/.deba_s3
#
# Usage:
#   ./push_to_s3.sh path/to/video.mp4                 # public URL (object made public)
#   ./push_to_s3.sh path/to/video.mp4 reels/skit3.mp4 # custom key/path in bucket
#   ./push_to_s3.sh clip.mov --mp4                     # transcode to web mp4 (H.264) first
#   ./push_to_s3.sh report.pdf --share                # time-limited presigned link (7 days), private object
set -euo pipefail
[ -f "$HOME/.deba_s3" ] && source "$HOME/.deba_s3"
: "${S3_BUCKET:?Set S3_BUCKET in ~/.deba_s3 or env}"
: "${AWS_REGION:=us-east-1}"

FILE="${1:?Usage: push_to_s3.sh <file> [key] [--mp4] [--share]}"; shift || true
KEY=""; MP4=0; SHARE=0
for a in "$@"; do
  case "$a" in
    --mp4) MP4=1 ;; --share) SHARE=1 ;; *) KEY="$a" ;;
  esac
done
[ -f "$FILE" ] || { echo "No such file: $FILE" >&2; exit 1; }

if [ "$MP4" = "1" ]; then
  command -v ffmpeg >/dev/null || { echo "ffmpeg not installed (brew install ffmpeg)"; exit 1; }
  OUT="${FILE%.*}.web.mp4"
  echo "Transcoding -> $OUT ..."
  ffmpeg -y -i "$FILE" -vf "scale='min(1080,iw)':-2" -c:v libx264 -preset veryfast -crf 23 -c:a aac -movflags +faststart "$OUT" >/dev/null 2>&1
  FILE="$OUT"
fi

[ -n "$KEY" ] || KEY="$(date +%Y/%m)/$(basename "$FILE")"
echo "Uploading $FILE -> s3://$S3_BUCKET/$KEY ..."

if [ "$SHARE" = "1" ]; then
  aws s3 cp "$FILE" "s3://$S3_BUCKET/$KEY" --region "$AWS_REGION"
  URL="$(aws s3 presign "s3://$S3_BUCKET/$KEY" --expires-in 604800 --region "$AWS_REGION")"
  echo "Presigned (7-day) link:"; echo "$URL"
else
  aws s3 cp "$FILE" "s3://$S3_BUCKET/$KEY" --acl public-read --region "$AWS_REGION"
  if [ -n "${CLOUDFRONT_DOMAIN:-}" ]; then URL="https://$CLOUDFRONT_DOMAIN/$KEY"
  else URL="https://$S3_BUCKET.s3.$AWS_REGION.amazonaws.com/$KEY"; fi
  echo "Public URL:"; echo "$URL"
fi
