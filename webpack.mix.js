let mix = require('laravel-mix');

const path = require('path');
let directory = path.basename(path.resolve(__dirname));

const source = 'dev-extensions/kernel';
const dist = 'public/vendor/core/kernel/' + directory;

mix
    .sass(source + '/resources/assets/sass/_social-icons.scss', dist + '/css');

mix.styles([
    'public/vendor/core/core/base/css/core.css',
    dist + '/css/_social-icons.css'
], 'public/vendor/core/core/base/css/core_merged.css');

mix.copy('public/vendor/core/core/base/css/core_merged.css', 'public/vendor/core/core/base/css/core.css');

// mix
//     .copyDirectory(dist + '/css', source + '/public/css');