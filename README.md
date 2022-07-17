# WXRX - Automated Weather Satellite Image Reception

This is a collection of scripts for recording and decoding of NOAA Satellite images, and generating
static web pages with the decoded image using any of the popular RTL2832U-based Software Defined Radios.

*Warning*: These scripts are still very much a work in progress and, in my opinion, are not ready for
a major version number.

[See it in action](https://wxrx.kenbarbour.com/)

## Dependencies
* BASH
* [wxtoimg](https://wxtoimgrestored.xyz) - *Note*: this may require `~/.wxtoimglic` and `~/.wxtoimgrc` to run properly
* [predict](https://www.qsl.net/kd2bd/predict.html)
* ImageMagick
* [shunit2](https://github.com/kward/shunit2) (for development and testing)
* rtl_fm
* atd

## Usage
Use `wxrx help` or `wxrx <command> help` for helptext for any of the scripts.

* `wxrx update` - Fetches telemetry data from Celestrak into the current directory. Needed for predictions
* `wxrx predict` - Predicts satellite passes (default: passes rising above 45 degrees within the next 24 hours)
* `wxrx record --duration {seconds} --noaa-{15|18|19} ` - Records a transmission from a satellite currently overhead to a wavfile
* `wxrx decode [--timestamp <unix-timestamp>] [--satellite noaa-(15|18|19)] <wavfile>` - Create images for a recorded transmission using wxtoimg
* `wxrx web` - Search directory tree within current directory and generates a website.  Uses templates stored in `WXRX_WEB_TEMPLATES` (default: wxrx/web/templates; see lib/web-templates for examples), and places generated files in `WXRX_WEB_PUBDIR` (default wxrx/web/public)
* `wxrx pass --noaa-{15|18|19} --duration {seconds}` - Handles the recording, decoding, and website generation of a single pass
* `wxrx schedule` - Predicts future passes and uses `atd` to run `wxrx pass` to handle them

### Example usage
* Set `wxrx/web/public` as a web server document root
* Add `wxrx update && wxrx schedule` as a daily cronjoba

## Further reading
[github.com/nootropicdesign/wx-ground-station](https://github.com/nootropicdesign/wx-ground-station)
