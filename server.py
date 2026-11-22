from flask import Flask, request, jsonify
import yt_dlp

app = Flask(__name__)

@app.route('/search')
def search():
    query = request.args.get('q')
    if not query:
        return jsonify({'error': 'Empty query'}), 400
    
    ydl_opts = {
        'format': 'bestaudio/best',
        'noplaylist': True,
        'quiet': True,
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            # Ищем видео по запросу
            info = ydl.extract_info(f"ytsearch1:{query}", download=False)
            if 'entries' in info and info['entries']:
                video = info['entries'][0]
                return jsonify({
                    'title': video.get('title', 'Unknown'),
                    'artist': video.get('uploader', 'Unknown'),
                    'url': video.get('url'), # Прямая ссылка на аудио
                    'duration': video.get('duration', 0),
                    'thumbnail': video.get('thumbnail', '')
                })
            else:
                return jsonify({'error': 'Not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
