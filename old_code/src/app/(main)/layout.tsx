import BottomNavigation from "@/components/BottomNavigation";

export default function MainLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <main className="container">
        {children}
      </main>
      <BottomNavigation />
    </>
  );
}
