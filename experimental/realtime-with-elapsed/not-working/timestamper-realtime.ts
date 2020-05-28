// const process = require('process');

process.stdin.setEncoding('utf8');

let last_date = Date.now();
process.stdin.on('readable', () => {
    let chunk;
    let line = '';
    // Use a loop to make sure we read all available data.
    while ((chunk = process.stdin.read()) !== null) {
        line += chunk;
        let m;
        while (m = line.match(/^([^\n]*)\n(.*)/)) {
            const next_date = Date.now();
            process.stdout.write(""+(next_date/1000)+"\t"+m[0]);
            last_date = next_date;
            line = m[1];
        }
    }
});

setTimeout( (arg)=> {
    const next_date = Date.now();
    process.stdout.clearLine(null);
    process.stdout.cursorTo(0);
    process.stdout.write("" + ((next_date-last_date)/1000) +"");

}, 100,);
process.stdin.on('end', () => {
    process.stdout.write('end');
});
