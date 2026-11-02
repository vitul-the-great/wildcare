import "./globals.css";
export const metadata = { title: "Wildcare | Wildlife Rescue & Rehabilitation", description: "Every rescue. Every recovery. One place." };
export default function Layout({children}: {children: React.ReactNode}) { return <html lang="en"><body>{children}</body></html>; }