import {replaceInFileSync} from 'replace-in-file';
const VERSION = process.env.npm_package_version;
const options = {
  files: './mta.yaml',
  from: /version: (\d+\.)?(\d+\.)?(\*|\d+)/g,
  to: 'version: ' + VERSION,
};

try {
  const results = replaceInFileSync(options);
  console.log('Replacement results:', results);
}
catch (error) {
  console.error('Error occurred:', error);
}