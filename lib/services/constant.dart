const domain = "https://music.youtube.com/";
const String baseUrl = '${domain}youtubei/v1/';
const youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
const fixedParms = '?prettyPrint=false&alt=json&key=$youtubeApiKey';
const userAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36';
