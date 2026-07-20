import { computed, onMounted, onUnmounted, ref } from 'vue';

interface WindowSize {
  windowWidth: number;
  windowHeight: number;
}

type WindowResizeHandler = (size: WindowSize) => void;

type UniWindowApi = typeof uni & {
  getWindowInfo?: () => WindowSize;
  onWindowResize?: (handler: WindowResizeHandler) => void;
  offWindowResize?: (handler: WindowResizeHandler) => void;
  getSystemInfoSync?: () => WindowSize;
};

function readWindowSize(): WindowSize {
  const uniWindow = uni as UniWindowApi;
  const info = uniWindow.getWindowInfo?.() ?? uniWindow.getSystemInfoSync?.();

  return {
    windowWidth: Number(info?.windowWidth ?? 0),
    windowHeight: Number(info?.windowHeight ?? 0)
  };
}

export function useViewportProfile() {
  const width = ref(0);
  const height = ref(0);

  function update(size = readWindowSize()) {
    width.value = size.windowWidth;
    height.value = size.windowHeight;
  }

  const isShortScreen = computed(() => height.value > 0 && height.value <= 720);
  const isCoverScreen = computed(() => {
    if (!width.value || !height.value) {
      return false;
    }

    const shortSide = Math.min(width.value, height.value);
    const longSide = Math.max(width.value, height.value);
    const aspect = longSide / shortSide;

    return shortSide <= 430 && longSide <= 560 && aspect <= 1.35;
  });

  const resizeHandler: WindowResizeHandler = (size) => update(size);

  onMounted(() => {
    update();
    (uni as UniWindowApi).onWindowResize?.(resizeHandler);
  });

  onUnmounted(() => {
    (uni as UniWindowApi).offWindowResize?.(resizeHandler);
  });

  return {
    width,
    height,
    isShortScreen,
    isCoverScreen
  };
}
