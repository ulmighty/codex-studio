async function main(): Promise<void> {
  if (!('gpu' in navigator)) {
    console.log('no webgpu');
    return;
  }
  console.log('webgpu available');
}

main();
