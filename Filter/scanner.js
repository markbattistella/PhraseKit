/**
 * @file scanner.js
 * @description This script processes JSON files containing word lists and categorizes words into different categories based on specific rules. The categories include "pending," "safe," "unsafe," and "incompatible." The script also provides detailed logs for each file processed, including counts of words moved or skipped.
 * @version 1.0.0
 * @license MIT
 */

/**
 * @constant {Set<string>} blacklist
 * @description A set of words considered "unsafe," loaded from the prohibited.json file. Words found in this set are categorized as "unsafe."
 */
const blacklist = new Set(require('./prohibited.json')); // Assuming you run from the Filter directory

/**
 * @function processJsonFile
 * @description Processes a single JSON file by categorizing words into "safe," "unsafe," or "incompatible" based on specific criteria. Logs detailed information about the processing.
 * @param {string} filePath - The path to the JSON file to be processed.
 * @param {Array<string>} rescanOptions - The categories to rescan or process. Can include "pending," "safe," "unsafe," and "all."
 * @param {number} index - The index of the current file being processed, used for logging.
 * @param {number} totalFiles - The total number of files to be processed, used for logging.
 */
const processJsonFile = (filePath, rescanOptions, index, totalFiles) => {
  const fileName = path.basename(filePath);
  console.log(`[${index + 1} / ${totalFiles}] WORKING ON FILE`);
  console.log(`  - File: "${fileName}"`);

  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

  // Extract categories from the JSON data
  const { pending = [], safe = [], unsafe = [], incompatible = [] } = data;

  console.log(`  - Initial counts:`);
  console.log(`      | Pending      | ${String(pending.length).padStart(6)}`);
  console.log(`      | Safe         | ${String(safe.length).padStart(6)}`);
  console.log(`      | Unsafe       | ${String(unsafe.length).padStart(6)}`);
  console.log(`      | Incompatible | ${String(incompatible.length).padStart(6)}`);

  // Arrays to store the new categorization
  let newSafe = [...safe];  // Keep existing safe words
  let newUnsafe = [...unsafe];  // Keep existing unsafe words
  let newIncompatible = [...incompatible];  // Keep existing incompatible words

  // Counters for logging
  let movedToSafe = 0;
  let movedToUnsafe = 0;
  let movedToIncompatible = 0;
  let skippedSafe = 0;
  let skippedUnsafe = 0;

  /**
   * @function processWords
   * @description Processes a list of words and categorizes them into "safe," "unsafe," or "incompatible" based on whether they contain spaces or are found in the blacklist.
   * @param {Array<string>} words - The list of words to be processed.
   * @param {string} category - The category of words being processed (e.g., "pending," "safe," "unsafe").
   */
  const processWords = (words, category) => {
    console.log(`  - Processing "${category}" category with ${words.length} words`);
    words.forEach(word => {
      if (word.includes(' ')) {
        newIncompatible.push(word);
        if (category === 'pending') movedToIncompatible++;
      } else if (blacklist.has(word)) {
        newUnsafe.push(word);
        if (category === 'pending') movedToUnsafe++;
        else skippedUnsafe++;
      } else {
        newSafe.push(word);
        if (category === 'pending') movedToSafe++;
        else skippedSafe++;
      }
    });
  };

  // Determine which categories to process
  if (rescanOptions.includes('all')) {
    newSafe.length = 0; // Clear safe before reprocessing
    newUnsafe.length = 0; // Clear unsafe before reprocessing
    newIncompatible.length = 0; // Clear incompatible before reprocessing
    processWords(pending, 'pending');
    processWords(safe, 'safe');
    processWords(unsafe, 'unsafe');
  } else {
    if (rescanOptions.length === 0 || rescanOptions.includes('pending')) {
      processWords(pending, 'pending');
    }
    if (rescanOptions.includes('safe')) {
      newSafe.length = 0; // Clear safe before reprocessing
      processWords(safe, 'safe');
    }
    if (rescanOptions.includes('unsafe')) {
      newUnsafe.length = 0; // Clear unsafe before reprocessing
      processWords(unsafe, 'unsafe');
    }
  }

  // Remove duplicates and sort the lists
  newSafe = Array.from(new Set(newSafe)).sort();
  newUnsafe = Array.from(new Set(newUnsafe)).sort();
  newIncompatible = Array.from(new Set(newIncompatible)).sort();

  const output = {
    pending: [], // After processing, pending is empty
    safe: newSafe,
    unsafe: newUnsafe,
    incompatible: newIncompatible
  };

  const tempFilePath = filePath + '.tmp';

  // Write to a temporary file with minified JSON
  fs.writeFileSync(tempFilePath, JSON.stringify(output, null, 0));

  // Rename the temporary file to overwrite the original file
  fs.renameSync(tempFilePath, filePath);

  console.log(`  - Moved:`);
  console.log(`      | ${String(movedToSafe).padStart(5)} words: Pending --> Safe`);
  console.log(`      | ${String(movedToUnsafe).padStart(5)} words: Pending --> Unsafe`);
  console.log(`      | ${String(movedToIncompatible).padStart(5)} words: Pending --> Incompatible`);
  console.log(`  - Skipped:`);
  console.log(`      | ${String(skippedSafe).padStart(5)} words already in Safe`);
  console.log(`      | ${String(skippedUnsafe).padStart(5)} words already in Unsafe`);
  console.log(`  - Processed and updated\n`);
};

/**
 * @function getAllJsonFiles
 * @description Recursively retrieves all JSON files from a specified directory.
 * @param {string} baseDir - The base directory to search for JSON files.
 * @returns {Array<string>} - An array of file paths to the JSON files found.
 */
const getAllJsonFiles = (baseDir) => {
  let results = [];

  function traverseDir(currentDir) {
    const list = fs.readdirSync(currentDir);

    list.forEach(file => {
      const filePath = path.join(currentDir, file);
      const stat = fs.statSync(filePath);

      if (stat && stat.isDirectory()) {
        traverseDir(filePath); // Recurse into directories
      } else if (file.endsWith('.json')) {
        results.push(filePath); // Only add .json files
      }
    });
  }

  traverseDir(baseDir);
  return results;
};

/**
 * @function main
 * @description The main function that processes all JSON files in the specified directory based on the provided rescan options.
 * @param {string} baseDir - The base directory containing the JSON files to process.
 * @param {Array<string>} rescanOption - The categories to rescan or process. Can include "pending," "safe," "unsafe," and "all."
 */
const main = (baseDir, rescanOption) => {
  const files = getAllJsonFiles(baseDir);

  if (files.length === 0) {
    console.error('No files found matching the pattern.');
    return;
  }

  console.log(`\n[i] FOUND ${files.length} JSON FILES\n`);

  files.forEach((filePath, index) => processJsonFile(filePath, rescanOption, index, files.length));

  console.log('[i] PROCESS COMPLETE');
};

// Get the base directory and rescan option from the command line arguments and run the script
const [baseDir, rescanOptionArg] = process.argv.slice(2);

if (!baseDir) {
  console.error('Usage: node scanner.js /path/to/files <rescan_option>');
  console.error('Rescan options: pending (default), safe, unsafe, all');
  process.exit(1);
}

const rescanOption = rescanOptionArg ? rescanOptionArg.split(',') : [];

main(path.resolve(baseDir), rescanOption);
