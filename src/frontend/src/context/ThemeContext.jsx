import { createContext, useContext, useState } from "react";

const ThemeContext = createContext();

export const ThemeProvider = ({ children }) => {
  const [dark, setDark] = useState(false);
  return (
    <ThemeContext.Provider value={{ dark, setDark }}>
      <div className={dark ? "bg-gray-900 text-white min-h-screen" : "bg-white text-gray-900 min-h-screen"}>
        {children}
      </div>
    </ThemeContext.Provider>
  );
};

export const useTheme = () => useContext(ThemeContext);
