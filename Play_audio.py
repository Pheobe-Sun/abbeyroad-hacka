from pydub import AudioSegment
from pydub.playback import play


sound_load_1 = "test_voice.wav"
sound_play_1 = AudioSegment.from_wav(sound_load_1)

# convert audio
# awesome.export(target_loc, format="mp3")

play(sound_play_1)


